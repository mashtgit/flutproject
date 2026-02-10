import type { NextFunction, Request, Response } from 'express';
import { AuthService } from '../services/auth.service.js';
import { UserService } from '../services/user.service.js';
import { logger } from '../utils/logger.js';
import { AppError } from './errorHandler.js';

// Extend Express Request interface to include user
declare global {
  namespace Express {
    interface Request {
      user?: any;
    }
  }
}

// Authentication middleware
export const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(new AppError('Access denied. No token provided.', 401));
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
      return next(new AppError('Access denied. No token provided.', 401));
    }

    // Verify Firebase ID token using real AuthService
    const decodedToken = await AuthService.verifyToken(token);

    // Attach user to request
    req.user = decodedToken;

    logger.info(`Authenticated user: ${decodedToken.uid} (${decodedToken.email})`);
    next();

  } catch (error) {
    logger.error('Authentication error:', error);
    next(error);
  }
};

// Optional authentication middleware (doesn't fail if no token)
export const optionalAuth = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
      return next();
    }

    // Verify Firebase ID token
    const decodedToken = await AuthService.verifyToken(token);

    // Attach user to request
    req.user = decodedToken;

    logger.info(`Optional auth user: ${decodedToken.uid} (${decodedToken.email})`);
    next();

  } catch (error) {
    logger.warn('Optional authentication failed:', error);
    // Don't fail, just continue without user
    next();
  }
};

// Authorization middleware for specific roles
export const authorize = (...roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(new AppError('Authentication required.', 401));
    }

    // Check if user has any of the required roles
    const hasRole = roles.some(role => req.user.customClaims?.[role]);
    
    if (!hasRole) {
      return next(new AppError('Insufficient permissions.', 403));
    }

    next();
  };
};

// Admin authorization middleware
export const requireAdmin = authorize('admin');

// User authorization middleware (check if user is accessing their own resource)
export const requireOwnership = (userIdParam: string = 'userId') => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(new AppError('Authentication required.', 401));
    }

    const requestedUserId = req.params[userIdParam];
    const currentUserId = req.user.uid;

    // Allow if user is admin or accessing their own resource
    if (req.user.customClaims?.admin || requestedUserId === currentUserId) {
      return next();
    }

    return next(new AppError('Access denied. You can only access your own resources.', 403));
  };
};

// Create user middleware - automatically creates user profile on first auth
export const createUserOnAuth = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(new AppError('Access denied. No token provided.', 401));
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
      return next(new AppError('Access denied. No token provided.', 401));
    }

    // Verify token and get user info
    const decodedToken = await AuthService.verifyToken(token);
    
    // Create user profile if it doesn't exist
    await UserService.createUserOnAuth(
      decodedToken.uid,
      decodedToken.email || '',
      decodedToken.displayName,
      decodedToken.photoURL
    );

    // Attach user to request
    req.user = decodedToken;

    logger.info(`User profile created/verified: ${decodedToken.uid}`);
    next();

  } catch (error) {
    logger.error('Create user on auth failed:', error);
    next(error);
  }
};