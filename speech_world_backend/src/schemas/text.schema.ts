import Joi from 'joi';

export const textSchema = {
  createText: {
    body: Joi.object({
      title: Joi.string().min(2).max(200).required(),
      content: Joi.string().min(10).required(),
      category: Joi.string().required(),
      difficulty: Joi.string().valid('beginner', 'intermediate', 'advanced').required(),
      language: Joi.string().min(2).max(5).default('en'),
      estimatedReadingTime: Joi.number().integer().min(1).max(120).optional(),
      wordCount: Joi.number().integer().min(1).optional(),
      tags: Joi.array().items(Joi.string()).default([]),
      author: Joi.string().optional(),
      isPublic: Joi.boolean().default(true),
      metadata: Joi.object({
        vocabulary: Joi.array().items(Joi.string()).default([]),
        grammarPoints: Joi.array().items(Joi.string()).default([]),
        culturalNotes: Joi.string().optional(),
        audioUrl: Joi.string().uri().optional(),
        imageUrl: Joi.string().uri().optional(),
      }).optional(),
    }),
  },
  
  updateText: {
    params: Joi.object({
      textId: Joi.string().required(),
    }),
    body: Joi.object({
      title: Joi.string().min(2).max(200).optional(),
      content: Joi.string().min(10).optional(),
      category: Joi.string().optional(),
      difficulty: Joi.string().valid('beginner', 'intermediate', 'advanced').optional(),
      language: Joi.string().min(2).max(5).optional(),
      estimatedReadingTime: Joi.number().integer().min(1).max(120).optional(),
      wordCount: Joi.number().integer().min(1).optional(),
      tags: Joi.array().items(Joi.string()).optional(),
      author: Joi.string().optional(),
      isPublic: Joi.boolean().optional(),
      metadata: Joi.object({
        vocabulary: Joi.array().items(Joi.string()).optional(),
        grammarPoints: Joi.array().items(Joi.string()).optional(),
        culturalNotes: Joi.string().optional(),
        audioUrl: Joi.string().uri().optional(),
        imageUrl: Joi.string().uri().optional(),
      }).optional(),
    }),
  },
  
  getText: {
    params: Joi.object({
      textId: Joi.string().required(),
    }),
  },
  
  deleteText: {
    params: Joi.object({
      textId: Joi.string().required(),
    }),
  },
  
  getTexts: {
    query: Joi.object({
      category: Joi.string().optional(),
      difficulty: Joi.string().valid('beginner', 'intermediate', 'advanced').optional(),
      language: Joi.string().min(2).max(5).optional(),
      isPublic: Joi.boolean().optional(),
      tags: Joi.array().items(Joi.string()).optional(),
      limit: Joi.number().integer().min(1).max(100).default(20),
      offset: Joi.number().integer().min(0).default(0),
      sortBy: Joi.string().valid('createdAt', 'title', 'readingTime').default('createdAt'),
      sortOrder: Joi.string().valid('asc', 'desc').default('desc'),
    }),
  },
  
  getTextStats: {
    params: Joi.object({
      textId: Joi.string().required(),
    }),
  },
  
  getTextProgress: {
    params: Joi.object({
      textId: Joi.string().required(),
      userId: Joi.string().required(),
    }),
  },
  
  updateTextProgress: {
    params: Joi.object({
      textId: Joi.string().required(),
      userId: Joi.string().required(),
    }),
    body: Joi.object({
      currentWordIndex: Joi.number().integer().min(0).optional(),
      readingTime: Joi.number().integer().min(0).optional(),
      completed: Joi.boolean().optional(),
      accuracy: Joi.number().min(0).max(100).optional(),
      mistakes: Joi.array().items(Joi.object({
        word: Joi.string().required(),
        expected: Joi.string().required(),
        actual: Joi.string().required(),
        timestamp: Joi.date().timestamp().optional(),
      })).optional(),
    }),
  },
  
  getTextAnalytics: {
    params: Joi.object({
      textId: Joi.string().required(),
    }),
    query: Joi.object({
      startDate: Joi.date().optional(),
      endDate: Joi.date().optional(),
      userId: Joi.string().optional(),
    }),
  },
  
  searchTexts: {
    query: Joi.object({
      q: Joi.string().min(2).required(),
      category: Joi.string().optional(),
      difficulty: Joi.string().valid('beginner', 'intermediate', 'advanced').optional(),
      language: Joi.string().min(2).max(5).optional(),
      tags: Joi.array().items(Joi.string()).optional(),
      limit: Joi.number().integer().min(1).max(50).default(20),
      offset: Joi.number().integer().min(0).default(0),
    }),
  },
};