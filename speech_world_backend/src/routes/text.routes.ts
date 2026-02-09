import express from 'express';
import { authenticate, optionalAuth } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { validate, validateQuery } from '../middleware/validation.js';
import { textSchema } from '../schemas/text.schema.js';
import { TextService } from '../services/text.service.js';

const router = express.Router();

// Get all texts (public)
router.get('/',
  optionalAuth,
  validateQuery(textSchema.getTexts),
  asyncHandler(async (req: express.Request, res: express.Response) => {
    const { pageSize = 20, lastDoc } = req.query;
    
    const result = await TextService.getAllTexts(
      parseInt(pageSize as string), 
      lastDoc as any
    );
    
    res.json({
      success: true,
      data: result,
    });
  })
);

// Get text by ID
router.get('/:textId',
  optionalAuth,
  asyncHandler(async (req: express.Request, res: express.Response) => {
    const { textId } = req.params;
    
    const text = await TextService.getTextById(textId);
    
    res.json({
      success: true,
      data: text,
    });
  })
);

// Get texts by category
router.get('/category/:category',
  optionalAuth,
  validateQuery(textSchema.getTexts),
  asyncHandler(async (req: express.Request, res: express.Response) => {
    const { category } = req.params;
    const { pageSize = 20, lastDoc } = req.query;
    
    const result = await TextService.getTextsByCategory(
      category, 
      parseInt(pageSize as string), 
      lastDoc as any
    );
    
    res.json({
      success: true,
      data: result,
    });
  })
);

// Get texts by level
router.get('/level/:level',
  optionalAuth,
  validateQuery(textSchema.getTexts),
  asyncHandler(async (req: express.Request, res: express.Response) => {
    const { level } = req.params;
    const { pageSize = 20, lastDoc } = req.query;
    
    const result = await TextService.getTextsByLevel(
      level, 
      parseInt(pageSize as string), 
      lastDoc as any
    );
    
    res.json({
      success: true,
      data: result,
    });
  })
);

// Create text
router.post('/',
  authenticate,
  validate(textSchema.createText),
  asyncHandler(async (req: express.Request, res: express.Response) => {
    const userId = req.user.uid;
    const textData = req.body;
    
    const text = await TextService.createText(userId, textData);
    
    res.status(201).json({
      success: true,
      data: text,
    });
  })
);

// Update text
router.put('/:textId',
  authenticate,
  validate(textSchema.updateText),
  asyncHandler(async (req: express.Request, res: express.Response) => {
    const { textId } = req.params;
    const userId = req.user.uid;
    const updates = req.body;
    
    const text = await TextService.updateText(textId, userId, updates);
    
    res.json({
      success: true,
      data: text,
    });
  })
);

// Delete text
router.delete('/:textId',
  authenticate,
  asyncHandler(async (req: express.Request, res: express.Response) => {
    const { textId } = req.params;
    const userId = req.user.uid;
    
    await TextService.deleteText(textId, userId);
    
    res.json({
      success: true,
      message: 'Text deleted successfully',
    });
  })
);

// Publish text
router.post('/:textId/publish',
  authenticate,
  asyncHandler(async (req: express.Request, res: express.Response) => {
    const { textId } = req.params;
    const userId = req.user.uid;
    
    await TextService.publishText(textId, userId);
    
    res.json({
      success: true,
      message: 'Text published successfully',
    });
  })
);

// Get user's texts
router.get('/user/:userId',
  authenticate,
  validateQuery(textSchema.getTexts),
  asyncHandler(async (req: express.Request, res: express.Response) => {
    const { userId } = req.params;
    const currentUserId = req.user.uid;
    
    // Users can only access their own texts
    if (userId !== currentUserId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied',
      });
    }
    
    const { pageSize = 20, lastDoc } = req.query;
    
    const result = await TextService.getUserTexts(
      userId, 
      parseInt(pageSize as string), 
      lastDoc as any
    );
    
    return res.json({
      success: true,
      data: result,
    });
  })
);

// Search texts
router.get('/search/:searchTerm',
  optionalAuth,
  validateQuery(textSchema.searchTexts),
  asyncHandler(async (req: express.Request, res: express.Response) => {
    const { searchTerm } = req.params;
    const { pageSize = 20 } = req.query;
    
    const texts = await TextService.searchTexts(
      searchTerm, 
      parseInt(pageSize as string)
    );
    
    res.json({
      success: true,
      data: texts,
    });
  })
);

// Get text statistics
router.get('/:textId/stats',
  authenticate,
  asyncHandler(async (req: express.Request, res: express.Response) => {
    const { textId } = req.params;
    
    const stats = await TextService.getTextStats(textId);
    
    res.json({
      success: true,
      data: stats,
    });
  })
);

// Update text search index (admin only)
router.post('/:textId/search-index',
  authenticate,
  asyncHandler(async (req: express.Request, res: express.Response) => {
    const { textId } = req.params;
    
    await TextService.updateTextSearchIndex(textId);
    
    res.json({
      success: true,
      message: 'Search index updated successfully',
    });
  })
);

export { router as textRoutes };