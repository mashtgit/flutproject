import { auth, db } from '../config/firebase.js';
import { AppError } from '../middleware/errorHandler.js';
import { logger } from '../utils/logger.js';
import { FieldValue } from 'firebase-admin/firestore';

export class UserService {
  // Verify Firebase ID token
  static async verifyToken(token: string) {
    try {
      const decodedToken = await auth().verifyIdToken(token);
      const user = await auth().getUser(decodedToken.uid);

      return {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
        disabled: user.disabled,
        metadata: {
          creationTime: user.metadata.creationTime ? new Date(user.metadata.creationTime).toISOString() : undefined,
          lastSignInTime: user.metadata.lastSignInTime ? new Date(user.metadata.lastSignInTime).toISOString() : undefined,
        },
        customClaims: decodedToken.customClaims,
      };
    } catch (error: any) {
      logger.error('Token verification failed:', error);
      
      if (typeof error === 'object' && error !== null && 'code' in error) {
        const errorCode = error.code;
        
        switch (errorCode) {
          case 'auth/argument-error':
          case 'auth/invalid-argument':
            throw new AppError('Invalid token format.', 401);
          case 'auth/id-token-expired':
            throw new AppError('Token has expired.', 401);
          case 'auth/id-token-revoked':
            throw new AppError('Token has been revoked.', 401);
          case 'auth/invalid-id-token':
            throw new AppError('Invalid token.', 401);
          case 'auth/user-disabled':
            throw new AppError('User account has been disabled.', 401);
          case 'auth/user-not-found':
            throw new AppError('User not found.', 401);
          default:
            throw new AppError('Authentication failed.', 401);
        }
      }
      
      throw new AppError('Authentication failed.', 401);
    }
  }

  static async createCustomToken(uid: string) {
    try {
      const customToken = await auth().createCustomToken(uid);
      return { customToken };
    } catch (error: any) {
      logger.error('Custom token creation failed:', error);
      throw new AppError('Failed to create custom token', 500);
    }
  }

  static async revokeTokens(uid: string) {
    try {
      await auth().revokeRefreshTokens(uid);
      return { message: 'All refresh tokens have been revoked' };
    } catch (error: any) {
      logger.error('Token revocation failed:', error);
      throw new AppError('Failed to revoke tokens', 500);
    }
  }

  static async getUserByEmail(email: string) {
    try {
      const user = await auth().getUserByEmail(email);
      return {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
        disabled: user.disabled,
        metadata: {
          creationTime: user.metadata.creationTime ? new Date(user.metadata.creationTime).toISOString() : undefined,
          lastSignInTime: user.metadata.lastSignInTime ? new Date(user.metadata.lastSignInTime).toISOString() : undefined,
        },
        customClaims: user.customClaims,
      };
    } catch (error: any) {
      if (error?.code === 'auth/user-not-found') {
        throw new AppError('User not found', 404);
      }
      logger.error('Get user by email failed:', error);
      throw new AppError('Failed to get user', 500);
    }
  }

  static async getUserByUid(uid: string) {
    try {
      const user = await auth().getUser(uid);
      return {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
        disabled: user.disabled,
        metadata: {
          creationTime: user.metadata.creationTime ? new Date(user.metadata.creationTime).toISOString() : undefined,
          lastSignInTime: user.metadata.lastSignInTime ? new Date(user.metadata.lastSignInTime).toISOString() : undefined,
        },
        customClaims: user.customClaims,
      };
    } catch (error: any) {
      if (error?.code === 'auth/user-not-found') {
        throw new AppError('User not found', 404);
      }
      logger.error('Get user by UID failed:', error);
      throw new AppError('Failed to get user', 500);
    }
  }

  static async setCustomClaims(uid: string, claims: any) {
    try {
      await auth().setCustomUserClaims(uid, claims);
      return { message: 'Custom claims updated successfully' };
    } catch (error: any) {
      logger.error('Set custom claims failed:', error);
      throw new AppError('Failed to set custom claims', 500);
    }
  }

  static async updateUserDisabled(uid: string, disabled: boolean) {
    try {
      const user = await auth().updateUser(uid, { disabled });
      return {
        uid: user.uid,
        disabled: user.disabled,
        message: `User ${user.disabled ? 'disabled' : 'enabled'} successfully`,
      };
    } catch (error: any) {
      logger.error('Update user disabled status failed:', error);
      throw new AppError('Failed to update user', 500);
    }
  }

  static async listUsers(pageSize: number = 1000, nextPageToken?: string) {
    try {
      const result = await auth().listUsers(pageSize, nextPageToken);
      return {
        users: result.users.map((user: any) => ({
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoURL: user.photoURL,
          emailVerified: user.emailVerified,
          disabled: user.disabled,
          metadata: {
            creationTime: user.metadata.creationTime ? new Date(user.metadata.creationTime).toISOString() : undefined,
            lastSignInTime: user.metadata.lastSignInTime ? new Date(user.metadata.lastSignInTime).toISOString() : undefined,
          },
          customClaims: user.customClaims,
        })),
        nextPageToken: result.pageToken,
      };
    } catch (error: any) {
      logger.error('List users failed:', error);
      throw new AppError('Failed to list users', 500);
    }
  }

  static async deleteUser(uid: string) {
    try {
      await auth().deleteUser(uid);
      return { message: 'User deleted successfully' };
    } catch (error: any) {
      if (error?.code === 'auth/user-not-found') {
        throw new AppError('User not found', 404);
      }
      logger.error('Delete user failed:', error);
      throw new AppError('Failed to delete user', 500);
    }
  }

  static async updateUserProfile(uid: string, updates: any) {
    try {
      // Add updatedAt timestamp when updating profile
      const updatesWithTimestamp = {
        ...updates,
        updatedAt: FieldValue.serverTimestamp(),
      };
      
      const user = await auth().updateUser(uid, updates);
      
      // Also update Firestore profile if it exists
      const userRef = db().collection('users').doc(uid);
      const doc = await userRef.get();
      if (doc.exists) {
        await userRef.update(updatesWithTimestamp);
      }
      
      return {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        disabled: user.disabled,
        message: 'User profile updated successfully',
      };
    } catch (error: any) {
      if (error?.code === 'auth/user-not-found') {
        throw new AppError('User not found', 404);
      }
      logger.error('Update user profile failed:', error);
      throw new AppError('Failed to update user profile', 500);
    }
  }

  static async createUser(email: string, password: string, userData?: any) {
    try {
      const userRecord = await auth().createUser({
        email,
        password,
        displayName: userData?.displayName,
        photoURL: userData?.photoURL,
      });

      // Create user profile in Firestore with complete data
      await UserService.createUserProfile(userRecord.uid, {
        email: userRecord.email,
        displayName: userRecord.displayName,
        photoURL: userRecord.photoURL,
        credits: userData?.credits ?? 0,
        subscription: userData?.subscription ?? {
          planId: 'free',
          status: 'expired',
          validUntil: null,
        },
      });

      return {
        uid: userRecord.uid,
        email: userRecord.email,
        displayName: userRecord.displayName,
        photoURL: userRecord.photoURL,
        emailVerified: userRecord.emailVerified,
        disabled: userRecord.disabled,
        metadata: {
          creationTime: userRecord.metadata.creationTime ? new Date(userRecord.metadata.creationTime).toISOString() : undefined,
          lastSignInTime: userRecord.metadata.lastSignInTime ? new Date(userRecord.metadata.lastSignInTime).toISOString() : undefined,
        },
      };
    } catch (error: any) {
      logger.error('Create user failed:', error);
      
      if (error?.code) {
        switch (error.code) {
          case 'auth/email-already-exists':
            throw new AppError('Email already exists', 409);
          case 'auth/invalid-email':
            throw new AppError('Invalid email address', 400);
          case 'auth/operation-not-allowed':
            throw new AppError('Email/password accounts are not enabled', 400);
          case 'auth/weak-password':
            throw new AppError('Password is too weak', 400);
          default:
            throw new AppError('Failed to create user', 500);
        }
      }
      
      throw new AppError('Failed to create user', 500);
    }
  }

  // Create user profile in database on first authentication
  static async createUserOnAuth(
    uid: string,
    email: string,
    displayName?: string | null,
    photoURL?: string | null
  ) {
    try {
      logger.info(`Creating user profile for ${uid} (${email})`);
      
      // Create user profile in Firestore with default values
      // New users get 'free' subscription + 50 starter credits
      const result = await UserService.createUserProfile(uid, {
        email,
        displayName: displayName || null,
        photoURL: photoURL || null,
        credits: 50, // Starter credits for new users
        subscription: {
          planId: 'free',
          status: 'active',
          validUntil: null,
        },
      });
      
      logger.info(`✅ User profile created for ${uid} with 50 credits and free subscription`);
      return result;
    } catch (error: any) {
      logger.error('Create user on auth failed:', error);
      // Don't throw error here as it would prevent authentication
      // Just log and continue
      return { message: 'User profile creation skipped', error: error.message };
    }
  }

  // Create user profile in Firestore
  static async createUserProfile(uid: string, profileData: any) {
    try {
      const userRef = db().collection('users').doc(uid);
      
      // Check if user already exists
      const existingDoc = await userRef.get();
      if (existingDoc.exists) {
        logger.info(`User profile already exists for ${uid}`);
        return { message: 'User profile already exists', uid };
      }
      
      const dataToSet = {
        uid,
        email: profileData.email,
        displayName: profileData.displayName || null,
        photoURL: profileData.photoURL || null,
        credits: profileData.credits ?? 50, // Default 50 starter credits
        subscription: profileData.subscription ?? {
          planId: 'free',
          status: 'active', // Changed from 'expired' to 'active'
          validUntil: null,
        },
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        // Allow additional data from profileData
        ...profileData,
      };
      
      await userRef.set(dataToSet);
      logger.info(`✅ User profile created for ${uid} with ${dataToSet.credits} credits, plan: ${dataToSet.subscription.planId}`);
      return { message: 'User profile created successfully', uid, credits: dataToSet.credits };
    } catch (error: any) {
      logger.error('Create user profile in Firestore failed:', error);
      throw new AppError('Failed to create user profile in database', 500);
    }
  }

  // Get user profile
  static async getUserProfile(uid: string) {
    try {
      // Try to get from Firestore first
      const userRef = db().collection('users').doc(uid);
      const doc = await userRef.get();
      if (doc.exists) {
        return { uid, ...doc.data() };
      }

      // Fallback to Auth if not in Firestore
      const user = await auth().getUser(uid);
      return {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
        disabled: user.disabled,
        metadata: {
          creationTime: user.metadata.creationTime ? new Date(user.metadata.creationTime).toISOString() : undefined,
          lastSignInTime: user.metadata.lastSignInTime ? new Date(user.metadata.lastSignInTime).toISOString() : undefined,
        },
        customClaims: user.customClaims,
      };
    } catch (error: any) {
      if (error?.code === 'auth/user-not-found' || (error?.code === '5' && error.message?.includes('no such document'))) {
        throw new AppError('User not found', 404);
      }
      logger.error('Get user profile failed:', error);
      throw new AppError('Failed to get user profile', 500);
    }
  }

  // Get user statistics
  static async getUserStats(uid: string) {
    try {
      // TODO: Implement actual user statistics from your database
      // This is a placeholder implementation
      logger.info(`Getting stats for user ${uid}`);
      return {
        uid,
        textsCreated: 0,
        textsRead: 0,
        wordsLearned: 0,
        streakDays: 0,
        lastActivityDate: null,
      };
    } catch (error: any) {
      logger.error('Get user stats failed:', error);
      throw new AppError('Failed to get user statistics', 500);
    }
  }

  // Update user statistics
  static async updateUserStats(uid: string, stats: any) {
    try {
      // TODO: Implement actual user statistics update in your database
      logger.info(`Updating stats for user ${uid}`);
      return {
        uid,
        ...stats,
        message: 'User statistics updated successfully',
      };
    } catch (error: any) {
      logger.error('Update user stats failed:', error);
      throw new AppError('Failed to update user statistics', 500);
    }
  }

  // Get user texts
  static async getUserTexts(uid: string, pageSize: number = 20, lastDoc?: any) {
    try {
      // TODO: Implement actual user texts retrieval from your database
      logger.info(`Getting texts for user ${uid}`);
      return {
        texts: [],
        lastDoc: null,
        hasMore: false,
      };
    } catch (error: any) {
      logger.error('Get user texts failed:', error);
      throw new AppError('Failed to get user texts', 500);
    }
  }

  // Get all users (alias for listUsers)
  static async getAllUsers(pageSize: number = 10, lastDoc?: any) {
    try {
      return await this.listUsers(pageSize, lastDoc);
    } catch (error: any) {
      logger.error('Get all users failed:', error);
      throw new AppError('Failed to get all users', 500);
    }
  }

  // Search users
  static async searchUsers(searchTerm: string, pageSize: number = 10) {
    try {
      // TODO: Implement actual user search in your database
      // Firebase Auth doesn't support direct search, need to implement in Firestore
      logger.info(`Searching users with term: ${searchTerm}`);
      return {
        users: [],
        message: 'User search completed',
      };
    } catch (error: any) {
      logger.error('Search users failed:', error);
      throw new AppError('Failed to search users', 500);
    }
  }

  // Update user search index
  static async updateUserSearchIndex(uid: string) {
    try {
      // TODO: Implement actual user search index update in your database
      logger.info(`Updating search index for user ${uid}`);
      return { message: 'User search index updated successfully' };
    } catch (error: any) {
      logger.error('Update user search index failed:', error);
      throw new AppError('Failed to update user search index', 500);
    }
  }

  // Delete user profile from Firestore
  static async deleteUserProfile(uid: string) {
    try {
      const userRef = db().collection('users').doc(uid);
      await userRef.delete();
      logger.info(`User profile deleted from Firestore for ${uid}`);
      return { message: 'User profile deleted successfully from database' };
    } catch (error: any) {
      logger.error('Delete user profile from Firestore failed:', error);
      // If the document doesn't exist, it's not a failure for this operation
      if (error?.code === '5' && error.message?.includes('no such document')) {
          return { message: 'User profile not found in database, nothing to delete' };
      }
      throw new AppError('Failed to delete user profile from database', 500);
    }
  }
}
