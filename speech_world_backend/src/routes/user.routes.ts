import { Router } from 'express';
import asyncHandler from 'express-async-handler';
import { createUserOnAuth, requireOwnership } from '../middleware/auth.js';
import { UserService } from '../services/user.service.js';

const router = Router();

// Create user profile (requires authentication)
// Called when user first signs up
router.post('/profile', createUserOnAuth, asyncHandler(async (req, res, next) => {
  const userId = req.user.uid;
  const userEmail = req.user.email;
  const { displayName, photoURL, credits = 50, subscription = { planId: 'free', status: 'active' } } = req.body;

  const userProfile = await UserService.createUserProfile(userId, {
    email: userEmail,
    displayName: displayName || userEmail?.split('@')[0] || 'User',
    photoURL: photoURL || null,
    credits,
    subscription,
  });

  res.status(201).json({
    success: true,
    data: userProfile,
    message: 'User profile created successfully',
  });
}));

// Get user profile (requires authentication)
router.get('/profile', createUserOnAuth, asyncHandler(async (req, res, next) => {
  const userId = req.user.uid;
  const userProfile = await UserService.getUserProfile(userId);

  res.status(200).json({
    success: true,
    data: userProfile,
    message: 'User profile retrieved successfully',
  });
}));

// Update user profile (requires authentication)
router.put('/profile', createUserOnAuth, asyncHandler(async (req, res, next) => {

  const userId = req.user.uid;
  const updates = req.body;
  const updatedProfile = await UserService.updateUserProfile(userId, updates);

  res.status(200).json({
    success: true,
    data: updatedProfile,
    message: 'User profile updated successfully',
  });
}));

// Get user statistics (requires authentication)
router.get('/stats', createUserOnAuth, asyncHandler(async (req, res, next) => {
  const userId = req.user.uid;
  const stats = await UserService.getUserStats(userId);

  res.status(200).json({
    success: true,
    data: stats,
    message: 'User statistics retrieved successfully',
  });
}));

// Update user statistics (requires authentication)
router.put('/stats', createUserOnAuth, asyncHandler(async (req, res, next) => {
  const userId = req.user.uid;
  const stats = req.body;
  const updatedStats = await UserService.updateUserStats(userId, stats);

  res.status(200).json({
    success: true,
    data: updatedStats,
    message: 'User statistics updated successfully',
  });
}));

// Get user texts (requires authentication)
router.get('/texts', createUserOnAuth, asyncHandler(async (req, res, next) => {
  const userId = req.user.uid;
  const { pageSize = 20, lastDoc } = req.query;

  const result = await UserService.getUserTexts(
    userId,
    parseInt(pageSize as string),
    lastDoc as any
  );

  res.status(200).json({
    success: true,
    data: result,
    message: 'User texts retrieved successfully',
  });
}));

// Get all users (admin only)
router.get('/', asyncHandler(async (req, res, next) => {
  const { pageSize = 10, lastDoc } = req.query;

  const result = await UserService.getAllUsers(
    parseInt(pageSize as string),
    lastDoc as any
  );

  res.status(200).json({
    success: true,
    data: result,
    message: 'Users retrieved successfully',
  });
}));

// Search users (admin only)
router.get('/search', asyncHandler(async (req, res, next) => {
  const { searchTerm, pageSize = 10 } = req.query;

  if (!searchTerm || typeof searchTerm !== 'string') {
    res.status(400).json({
      success: false,
      message: 'Search term is required and must be a string',
    });
    return;
  }

  const users = await UserService.searchUsers(
    searchTerm as string,
    parseInt(pageSize as string)
  );

  res.status(200).json({
    success: true,
    data: users,
    message: 'Users search completed successfully',
  });
}));

// Update user search index (requires authentication)
router.post('/search-index', createUserOnAuth, asyncHandler(async (req, res, next) => {
  const userId = req.user.uid;
  const result = await UserService.updateUserSearchIndex(userId);

  res.status(200).json({
    success: true,
    ...result,
    message: 'Search index updated successfully',
  });
}));

// Delete user profile (requires authentication and ownership)
router.delete('/profile', createUserOnAuth, requireOwnership(), asyncHandler(async (req, res, next) => {
  const userId = req.user.uid;
  const result = await UserService.deleteUserProfile(userId);

  res.status(200).json({
    success: true,
    ...result,
    message: 'User profile deleted successfully',
  });
}));

// Get user by UID (admin only)
router.get('/:userId', asyncHandler(async (req, res, next) => {
  const { userId } = req.params;
  const userProfile = await UserService.getUserProfile(userId);

  res.status(200).json({
    success: true,
    data: userProfile,
    message: 'User profile retrieved successfully',
  });
}));

// Update user by UID (admin only)
router.put('/:userId', asyncHandler(async (req, res, next) => {
  const { userId } = req.params;
  const updates = req.body;
  const updatedProfile = await UserService.updateUserProfile(userId, updates);

  res.status(200).json({
    success: true,
    data: updatedProfile,
    message: 'User profile updated successfully',
  });
}));

// Delete user by UID (admin only)
router.delete('/:userId', asyncHandler(async (req, res, next) => {
  const { userId } = req.params;
  const result = await UserService.deleteUserProfile(userId);

  res.status(200).json({
    success: true,
    ...result,
    message: 'User profile deleted successfully',
  });
}));

export default router;