import { Router } from 'express';
import asyncHandler from 'express-async-handler';
import { createUserOnAuth } from '../middleware/auth.js';
import { AuthService } from '../services/auth.service.js';

const router = Router();

// Get current user profile (requires authentication)
router.get('/profile', createUserOnAuth, asyncHandler(async (req, res, next) => {
  const { uid, email, displayName, photoURL } = req.user;
  
  res.status(200).json({
    user: {
      uid,
      email,
      displayName,
      photoURL,
    },
    message: 'Profile retrieved successfully',
  });
}));

// Verify Firebase ID token
router.post('/verify-token', asyncHandler(async (req, res, next) => {
  const { token } = req.body;

  if (!token) {
    res.status(400).json({
      success: false,
      message: 'Token is required',
    });
    return;
  }

  const decodedToken = await AuthService.verifyToken(token);

  res.status(200).json({
    success: true,
    user: decodedToken,
    message: 'Token verified successfully',
  });
}));

// Create custom token for Firebase
router.post('/create-custom-token', asyncHandler(async (req, res, next) => {
  const { uid } = req.body;

  if (!uid) {
    res.status(400).json({
      success: false,
      message: 'User ID (uid) is required',
    });
    return;
  }

  const { customToken } = await AuthService.createCustomToken(uid);

  res.status(200).json({
    success: true,
    customToken,
    message: 'Custom token created successfully',
  });
}));

// Refresh user session
router.post('/refresh', createUserOnAuth, asyncHandler(async (req, res, next) => {
  const { uid } = req.user;

  const { customToken } = await AuthService.createCustomToken(uid);

  res.status(200).json({
    success: true,
    customToken,
    message: 'Session refreshed successfully',
  });
}));

// Revoke all refresh tokens for a user
router.post('/revoke-tokens', createUserOnAuth, asyncHandler(async (req, res, next) => {
  const { uid } = req.user;

  const result = await AuthService.revokeTokens(uid);

  res.status(200).json({
    success: true,
    ...result,
  });
}));

// Get user by email (admin only)
router.get('/user-by-email', asyncHandler(async (req, res, next) => {
  const { email } = req.query;

  if (!email || typeof email !== 'string') {
    res.status(400).json({
      success: false,
      message: 'Email is required and must be a string',
    });
    return;
  }

  const user = await AuthService.getUserByEmail(email);

  res.status(200).json({
    success: true,
    user,
    message: 'User retrieved successfully',
  });
}));

// Get user by UID
router.get('/user/:uid', asyncHandler(async (req, res, next) => {
  const { uid } = req.params;

  const user = await AuthService.getUserByUid(uid);

  res.status(200).json({
    success: true,
    user,
    message: 'User retrieved successfully',
  });
}));

// Update user profile
router.put('/user/:uid', asyncHandler(async (req, res, next) => {
  const { uid } = req.params;
  const updates = req.body;

  const user = await AuthService.updateUserProfile(uid, updates);

  res.status(200).json({
    success: true,
    user,
    message: 'User profile updated successfully',
  });
}));

// Set custom claims for user
router.post('/user/:uid/claims', asyncHandler(async (req, res, next) => {
  const { uid } = req.params;
  const { claims } = req.body;

  if (!claims || typeof claims !== 'object') {
    res.status(400).json({
      success: false,
      message: 'Claims object is required',
    });
    return;
  }

  const result = await AuthService.setCustomClaims(uid, claims);

  res.status(200).json({
    success: true,
    ...result,
  });
}));

// Disable/enable user account
router.patch('/user/:uid/disable', asyncHandler(async (req, res, next) => {
  const { uid } = req.params;
  const { disabled } = req.body;

  if (typeof disabled !== 'boolean') {
    res.status(400).json({
      success: false,
      message: 'Disabled flag must be a boolean',
    });
    return;
  }

  const result = await AuthService.updateUserDisabled(uid, disabled);

  res.status(200).json({
    success: true,
    ...result,
  });
}));

// List all users (admin only)
router.get('/users', asyncHandler(async (req, res, next) => {
  const { pageSize = 10, pageToken } = req.query;

  const result = await AuthService.listUsers(
    parseInt(pageSize as string),
    pageToken as string
  );

  res.status(200).json({
    success: true,
    ...result,
    message: 'Users retrieved successfully',
  });
}));

// Delete user (admin only)
router.delete('/user/:uid', asyncHandler(async (req, res, next) => {
  const { uid } = req.params;

  const result = await AuthService.deleteUser(uid);

  res.status(200).json({
    success: true,
    ...result,
  });
}));

export default router;