import Joi from 'joi';

export const userSchema = {
  createUser: {
    body: Joi.object({
      email: Joi.string().email().required(),
      password: Joi.string().min(6).max(128).required(),
      displayName: Joi.string().min(2).max(50).optional(),
      photoURL: Joi.string().uri().optional(),
      language: Joi.string().min(2).max(5).default('en'),
      preferences: Joi.object({
        theme: Joi.string().valid('light', 'dark', 'system').default('system'),
        notifications: Joi.boolean().default(true),
        autoSave: Joi.boolean().default(true),
        readingSpeed: Joi.number().integer().min(50).max(500).default(200),
        difficultyLevel: Joi.string().valid('beginner', 'intermediate', 'advanced').default('beginner'),
      }).optional(),
      metadata: Joi.object({
        lastLoginAt: Joi.date().optional(),
        totalReadingTime: Joi.number().integer().min(0).default(0),
        textsCompleted: Joi.number().integer().min(0).default(0),
        accuracy: Joi.number().min(0).max(100).default(0),
        streak: Joi.number().integer().min(0).default(0),
      }).optional(),
    }),
  },
  
  updateUser: {
    params: Joi.object({
      userId: Joi.string().required(),
    }),
    body: Joi.object({
      displayName: Joi.string().min(2).max(50).optional(),
      photoURL: Joi.string().uri().optional(),
      language: Joi.string().min(2).max(5).optional(),
      preferences: Joi.object({
        theme: Joi.string().valid('light', 'dark', 'system').optional(),
        notifications: Joi.boolean().optional(),
        autoSave: Joi.boolean().optional(),
        readingSpeed: Joi.number().integer().min(50).max(500).optional(),
        difficultyLevel: Joi.string().valid('beginner', 'intermediate', 'advanced').optional(),
      }).optional(),
      metadata: Joi.object({
        lastLoginAt: Joi.date().optional(),
        totalReadingTime: Joi.number().integer().min(0).optional(),
        textsCompleted: Joi.number().integer().min(0).optional(),
        accuracy: Joi.number().min(0).max(100).optional(),
        streak: Joi.number().integer().min(0).optional(),
      }).optional(),
    }),
  },
  
  getUser: {
    params: Joi.object({
      userId: Joi.string().required(),
    }),
  },
  
  deleteUser: {
    params: Joi.object({
      userId: Joi.string().required(),
    }),
  },
  
  getUsers: {
    query: Joi.object({
      limit: Joi.number().integer().min(1).max(100).default(20),
      offset: Joi.number().integer().min(0).default(0),
      sortBy: Joi.string().valid('createdAt', 'displayName', 'email').default('createdAt'),
      sortOrder: Joi.string().valid('asc', 'desc').default('desc'),
      search: Joi.string().optional(),
    }),
  },
  
  updateUserPreferences: {
    params: Joi.object({
      userId: Joi.string().required(),
    }),
    body: Joi.object({
      theme: Joi.string().valid('light', 'dark', 'system').optional(),
      notifications: Joi.boolean().optional(),
      autoSave: Joi.boolean().optional(),
      readingSpeed: Joi.number().integer().min(50).max(500).optional(),
      difficultyLevel: Joi.string().valid('beginner', 'intermediate', 'advanced').optional(),
    }),
  },
  
  updateUserMetadata: {
    params: Joi.object({
      userId: Joi.string().required(),
    }),
    body: Joi.object({
      lastLoginAt: Joi.date().optional(),
      totalReadingTime: Joi.number().integer().min(0).optional(),
      textsCompleted: Joi.number().integer().min(0).optional(),
      accuracy: Joi.number().min(0).max(100).optional(),
      streak: Joi.number().integer().min(0).optional(),
    }),
  },
  
  getUserStats: {
    params: Joi.object({
      userId: Joi.string().required(),
    }),
  },
  
  getUserProgress: {
    params: Joi.object({
      userId: Joi.string().required(),
    }),
    query: Joi.object({
      startDate: Joi.date().optional(),
      endDate: Joi.date().optional(),
      textId: Joi.string().optional(),
    }),
  },
  
  updateUserProgress: {
    params: Joi.object({
      userId: Joi.string().required(),
    }),
    body: Joi.object({
      textId: Joi.string().required(),
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
  
  getUserAchievements: {
    params: Joi.object({
      userId: Joi.string().required(),
    }),
  },
  
  updateUserAchievements: {
    params: Joi.object({
      userId: Joi.string().required(),
    }),
    body: Joi.object({
      achievements: Joi.array().items(Joi.object({
        id: Joi.string().required(),
        name: Joi.string().required(),
        description: Joi.string().required(),
        icon: Joi.string().uri().optional(),
        unlockedAt: Joi.date().optional(),
        progress: Joi.number().min(0).max(100).optional(),
      })).required(),
    }),
  },
  
  getUserSettings: {
    params: Joi.object({
      userId: Joi.string().required(),
    }),
  },
  
  updateUserSettings: {
    params: Joi.object({
      userId: Joi.string().required(),
    }),
    body: Joi.object({
      theme: Joi.string().valid('light', 'dark', 'system').optional(),
      notifications: Joi.boolean().optional(),
      autoSave: Joi.boolean().optional(),
      readingSpeed: Joi.number().integer().min(50).max(500).optional(),
      difficultyLevel: Joi.string().valid('beginner', 'intermediate', 'advanced').optional(),
      language: Joi.string().min(2).max(5).optional(),
    }),
  },
  
  // Additional schemas for user routes
  createProfile: {
    body: Joi.object({
      displayName: Joi.string().min(2).max(50).optional(),
      photoURL: Joi.string().uri().optional(),
      bio: Joi.string().max(500).optional(),
      location: Joi.string().max(100).optional(),
      website: Joi.string().uri().optional(),
      socialLinks: Joi.object({
        twitter: Joi.string().optional(),
        linkedin: Joi.string().optional(),
        github: Joi.string().optional(),
      }).optional(),
    }),
  },
  
  updateProfile: {
    body: Joi.object({
      displayName: Joi.string().min(2).max(50).optional(),
      photoURL: Joi.string().uri().optional(),
      bio: Joi.string().max(500).optional(),
      location: Joi.string().max(100).optional(),
      website: Joi.string().uri().optional(),
      socialLinks: Joi.object({
        twitter: Joi.string().optional(),
        linkedin: Joi.string().optional(),
        github: Joi.string().optional(),
      }).optional(),
    }),
  },
  
  getUserTexts: {
    query: Joi.object({
      pageSize: Joi.number().integer().min(1).max(100).default(20),
      lastDoc: Joi.string().optional(),
    }),
  },
  
  searchUsers: {
    query: Joi.object({
      searchTerm: Joi.string().min(2).max(100).required(),
      pageSize: Joi.number().integer().min(1).max(50).default(10),
    }),
  },
  
  getAllUsers: {
    query: Joi.object({
      pageSize: Joi.number().integer().min(1).max(100).default(10),
      lastDoc: Joi.string().optional(),
    }),
  },
  
  updateStats: {
    body: Joi.object({
      words: Joi.number().integer().min(0).optional(),
      correctWords: Joi.number().integer().min(0).optional(),
    }),
  },
};