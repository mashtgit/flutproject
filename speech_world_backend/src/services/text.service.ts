import { QueryDocumentSnapshot } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import { AppError } from '../middleware/errorHandler.js';
import { logger } from '../utils/logger.js';

export interface IText {
  id: string;
  title?: string;
  content?: string;
  category?: string;
  level?: string;
  author?: string;
  userId?: string;
  status?: string;
  createdAt?: Date;
  updatedAt?: Date;
  publishedAt?: Date;
  wordCount?: number;
  searchIndex?: string[];
  isPublic?: boolean;
}

export interface ITextData {
  title?: string;
  content?: string;
  category?: string;
  level?: string;
  author?: string;
  isPublic?: boolean;
}

export interface IPaginationParams {
  lastDoc?: QueryDocumentSnapshot;
}

export class TextService {
  private static readonly COLLECTION = 'texts';
  private static readonly PROGRESS_COLLECTION = 'user_progress';

  // Get all texts
  static async getAllTexts(pageSize: number = 20, lastDoc?: IPaginationParams) {
    try {
      let query = db().collection(this.COLLECTION)
        .where('status', '==', 'published')
        .orderBy('createdAt', 'desc')
        .limit(pageSize);
      
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      const texts: IText[] = [];
      let lastDocument: QueryDocumentSnapshot | null = null;

      snapshot.forEach((doc: QueryDocumentSnapshot) => {
        const data = doc.data();
        texts.push({
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate(),
          updatedAt: data.updatedAt?.toDate(),
        });
        lastDocument = doc;
      });

      return {
        texts,
        lastDocument,
        hasNext: snapshot.size === pageSize,
      };
    } catch (error) {
      logger.error('Get all texts failed:', error);
      throw new AppError('Failed to get texts', 500);
    }
  }

  // Get text by ID
  static async getTextById(textId: string) {
    try {
      const textDoc = await db().collection(this.COLLECTION).doc(textId).get();
      
      if (!textDoc.exists) {
        throw new AppError('Text not found', 404);
      }

      const data = textDoc.data();
      
      // Check if text is published or if user is admin
      if (data?.status !== 'published') {
        throw new AppError('Text not available', 404);
      }

      return {
        id: textDoc.id,
        ...data,
        createdAt: data?.createdAt?.toDate(),
        updatedAt: data?.updatedAt?.toDate(),
      };
    } catch (error) {
      logger.error('Get text by ID failed:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to get text', 500);
    }
  }

  // Get texts by category
  static async getTextsByCategory(category: string, pageSize: number = 20, lastDoc?: IPaginationParams) {
    try {
      let query = db().collection(this.COLLECTION)
        .where('category', '==', category)
        .where('status', '==', 'published')
        .orderBy('createdAt', 'desc')
        .limit(pageSize);
      
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      const texts: IText[] = [];
      let lastDocument: QueryDocumentSnapshot | null = null;

      snapshot.forEach((doc: QueryDocumentSnapshot) => {
        const data = doc.data();
        texts.push({
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate(),
          updatedAt: data.updatedAt?.toDate(),
        });
        lastDocument = doc;
      });

      return {
        texts,
        lastDocument,
        hasNext: snapshot.size === pageSize,
      };
    } catch (error) {
      logger.error('Get texts by category failed:', error);
      throw new AppError('Failed to get texts by category', 500);
    }
  }

  // Get texts by level
  static async getTextsByLevel(level: string, pageSize: number = 20, lastDoc?: IPaginationParams) {
    try {
      let query = db().collection(this.COLLECTION)
        .where('level', '==', level)
        .where('status', '==', 'published')
        .orderBy('createdAt', 'desc')
        .limit(pageSize);
      
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      const texts: IText[] = [];
      let lastDocument: QueryDocumentSnapshot | null = null;

      snapshot.forEach((doc: QueryDocumentSnapshot) => {
        const data = doc.data();
        texts.push({
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate(),
          updatedAt: data.updatedAt?.toDate(),
        });
        lastDocument = doc;
      });

      return {
        texts,
        lastDocument,
        hasNext: snapshot.size === pageSize,
      };
    } catch (error) {
      logger.error('Get texts by level failed:', error);
      throw new AppError('Failed to get texts by level', 500);
    }
  }

  // Create text
  static async createText(userId: string, textData: ITextData) {
    try {
      const now = new Date();
      const text = {
        ...textData,
        userId,
        status: 'draft',
        createdAt: now,
        updatedAt: now,
        wordCount: textData.content ? textData.content.split(/\s+/).length : 0,
        searchIndex: textData.title ? [textData.title.toLowerCase()] : [],
      };

      const docRef = await db().collection(this.COLLECTION).add(text);
      const createdDoc = await docRef.get();
      const createdData = createdDoc.data();

      return {
        id: docRef.id,
        ...createdData,
        createdAt: createdData?.createdAt?.toDate(),
        updatedAt: createdData?.updatedAt?.toDate(),
      };
    } catch (error) {
      logger.error('Create text failed:', error);
      throw new AppError('Failed to create text', 500);
    }
  }

  // Update text
  static async updateText(textId: string, userId: string, updates: ITextData) {
    try {
      const textDoc = await db().collection(this.COLLECTION).doc(textId).get();
      
      if (!textDoc.exists) {
        throw new AppError('Text not found', 404);
      }

      const textData = textDoc.data();
      
      // Check ownership (only admin or owner can update)
      if (textData?.userId !== userId && !textData?.isPublic) {
        throw new AppError('Access denied', 403);
      }

      const updateData = {
        ...updates,
        updatedAt: new Date(),
        wordCount: updates.content ? updates.content.split(/\s+/).length : textData?.wordCount,
      };

      await db().collection(this.COLLECTION).doc(textId).update(updateData);
      
      const updatedDoc = await db().collection(this.COLLECTION).doc(textId).get();
      const updatedData = updatedDoc.data();

      return {
        id: textId,
        ...updatedData,
        createdAt: updatedData?.createdAt?.toDate(),
        updatedAt: updatedData?.updatedAt?.toDate(),
      };
    } catch (error) {
      logger.error('Update text failed:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to update text', 500);
    }
  }

  // Delete text
  static async deleteText(textId: string, userId: string) {
    try {
      const textDoc = await db().collection(this.COLLECTION).doc(textId).get();
      
      if (!textDoc.exists) {
        throw new AppError('Text not found', 404);
      }

      const textData = textDoc.data();
      
      // Check ownership (only admin or owner can delete)
      if (textData?.userId !== userId && !textData?.isPublic) {
        throw new AppError('Access denied', 403);
      }

      // Delete associated progress records
      const progressSnapshot = await db().collection(this.PROGRESS_COLLECTION)
        .where('textId', '==', textId)
        .get();
      
      const batch = db().batch();
      progressSnapshot.forEach((doc: QueryDocumentSnapshot) => {
        batch.delete(doc.ref);
      });
      
      // Delete the text
      batch.delete(textDoc.ref);
      await batch.commit();

      return { message: 'Text deleted successfully' };
    } catch (error) {
      logger.error('Delete text failed:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to delete text', 500);
    }
  }

  // Publish text
  static async publishText(textId: string, userId: string) {
    try {
      const textDoc = await db().collection(this.COLLECTION).doc(textId).get();
      
      if (!textDoc.exists) {
        throw new AppError('Text not found', 404);
      }

      const textData = textDoc.data();
      
      // Check ownership
      if (textData?.userId !== userId) {
        throw new AppError('Access denied', 403);
      }

      await db().collection(this.COLLECTION).doc(textId).update({
        status: 'published',
        publishedAt: new Date(),
        updatedAt: new Date(),
      });

      return { message: 'Text published successfully' };
    } catch (error) {
      logger.error('Publish text failed:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to publish text', 500);
    }
  }

  // Get user's texts
  static async getUserTexts(userId: string, pageSize: number = 20, lastDoc?: IPaginationParams) {
    try {
      let query = db().collection(this.COLLECTION)
        .where('userId', '==', userId)
        .orderBy('createdAt', 'desc')
        .limit(pageSize);
      
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      const texts: IText[] = [];
      let lastDocument: QueryDocumentSnapshot | null = null;

      snapshot.forEach((doc: QueryDocumentSnapshot) => {
        const data = doc.data();
        texts.push({
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate(),
          updatedAt: data.updatedAt?.toDate(),
        });
        lastDocument = doc;
      });

      return {
        texts,
        lastDocument,
        hasNext: snapshot.size === pageSize,
      };
    } catch (error) {
      logger.error('Get user texts failed:', error);
      throw new AppError('Failed to get user texts', 500);
    }
  }

  // Search texts
  static async searchTexts(searchTerm: string, pageSize: number = 20) {
    try {
      const lowerSearchTerm = searchTerm.toLowerCase();
      
      const snapshot = await db().collection(this.COLLECTION)
        .where('status', '==', 'published')
        .where('searchIndex', 'array-contains', lowerSearchTerm)
        .limit(pageSize)
        .get();

      const texts: IText[] = [];
      snapshot.forEach((doc: QueryDocumentSnapshot) => {
        const data = doc.data();
        texts.push({
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate(),
          updatedAt: data.updatedAt?.toDate(),
        });
      });

      return texts;
    } catch (error) {
      logger.error('Search texts failed:', error);
      throw new AppError('Failed to search texts', 500);
    }
  }

  // Get text statistics
  static async getTextStats(textId: string) {
    try {
      const textDoc = await db().collection(this.COLLECTION).doc(textId).get();
      
      if (!textDoc.exists) {
        throw new AppError('Text not found', 404);
      }

      const progressSnapshot = await db().collection(this.PROGRESS_COLLECTION)
        .where('textId', '==', textId)
        .get();

      const totalAttempts = progressSnapshot.size;
      let totalCorrectWords = 0;
      let totalWords = 0;

      progressSnapshot.forEach((doc: QueryDocumentSnapshot) => {
        const data = doc.data();
        totalCorrectWords += data.correctWords || 0;
        totalWords += data.totalWords || 0;
      });

      const averageAccuracy = totalWords > 0 
        ? Math.round((totalCorrectWords / totalWords) * 100) 
        : 0;

      return {
        textId,
        totalAttempts,
        totalCorrectWords,
        totalWords,
        averageAccuracy,
      };
    } catch (error) {
      logger.error('Get text stats failed:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to get text statistics', 500);
    }
  }

  // Update text search index
  static async updateTextSearchIndex(textId: string) {
    try {
      const textDoc = await db().collection(this.COLLECTION).doc(textId).get();
      
      if (!textDoc.exists) {
        throw new AppError('Text not found', 404);
      }

      const textData = textDoc.data();
      const searchIndex: string[] = [];

      if (textData?.title) {
        searchIndex.push(textData.title.toLowerCase());
      }
      if (textData?.category) {
        searchIndex.push(textData.category.toLowerCase());
      }
      if (textData?.author) {
        searchIndex.push(textData.author.toLowerCase());
      }

      await db().collection(this.COLLECTION).doc(textId).update({
        searchIndex,
        updatedAt: new Date(),
      });

      return { message: 'Search index updated successfully' };
    } catch (error) {
      logger.error('Update text search index failed:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to update search index', 500);
    }
  }
}