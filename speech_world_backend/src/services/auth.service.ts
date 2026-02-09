import { auth } from '../config/firebase.js';
import { AppError } from '../middleware/errorHandler.js';
import { logger } from '../utils/logger.js';

export class AuthService {
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
    } catch (error) {
      logger.error('Token verification failed:', error);
      
      // Handle specific Firebase auth errors
      if (typeof error === 'object' && error !== null && 'code' in error) {
        const errorCode = (error as any).code;
        
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

  // Create custom token for server-side authentication
  static async createCustomToken(uid: string) {
    try {
      const customToken = await auth().createCustomToken(uid);
      return { customToken };
    } catch (error) {
      logger.error('Custom token creation failed:', error);
      throw new AppError('Failed to create custom token', 500);
    }
  }

  // Revoke all refresh tokens for a user
  static async revokeTokens(uid: string) {
    try {
      await auth().revokeRefreshTokens(uid);
      
      return { message: 'All refresh tokens have been revoked' };
    } catch (error) {
      logger.error('Token revocation failed:', error);
      throw new AppError('Failed to revoke tokens', 500);
    }
  }

  // Get user by email
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
    } catch (error) {
      if (typeof error === 'object' && error !== null && 'code' in error && error.code === 'auth/user-not-found') {
        throw new AppError('User not found', 404);
      }
      logger.error('Get user by email failed:', error);
      throw new AppError('Failed to get user', 500);
    }
  }

  // Get user by UID
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
    } catch (error) {
      if (typeof error === 'object' && error !== null && 'code' in error && error.code === 'auth/user-not-found') {
        throw new AppError('User not found', 404);
      }
      logger.error('Get user by UID failed:', error);
      throw new AppError('Failed to get user', 500);
    }
  }

  // Set custom user claims
  static async setCustomClaims(uid: string, claims: any) {
    try {
      await auth().setCustomUserClaims(uid, claims);
      return { message: 'Custom claims updated successfully' };
    } catch (error) {
      logger.error('Set custom claims failed:', error);
      throw new AppError('Failed to set custom claims', 500);
    }
  }

  // Update user disabled status
  static async updateUserDisabled(uid: string, disabled: boolean) {
    try {
      const user = await auth().updateUser(uid, { disabled });
      return {
        uid: user.uid,
        disabled: user.disabled,
        message: `User ${user.disabled ? 'disabled' : 'enabled'} successfully`,
      };
    } catch (error) {
      logger.error('Update user disabled status failed:', error);
      throw new AppError('Failed to update user', 500);
    }
  }

  // List users with pagination
  static async listUsers(pageSize: number = 1000, nextPageToken?: string) {
    try {
      const result = await auth().listUsers(pageSize, nextPageToken);
      return {
        users: result.users.map(user => ({
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
    } catch (error) {
      logger.error('List users failed:', error);
      throw new AppError('Failed to list users', 500);
    }
  }

  // Delete user
  static async deleteUser(uid: string) {
    try {
      await auth().deleteUser(uid);
      return { message: 'User deleted successfully' };
    } catch (error) {
      if (typeof error === 'object' && error !== null && 'code' in error && error.code === 'auth/user-not-found') {
        throw new AppError('User not found', 404);
      }
      logger.error('Delete user failed:', error);
      throw new AppError('Failed to delete user', 500);
    }
  }

  // Update user profile
  static async updateUserProfile(uid: string, updates: any) {
    try {
      const user = await auth().updateUser(uid, updates);
      return {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        disabled: user.disabled,
        message: 'User profile updated successfully',
      };
    } catch (error) {
      if (typeof error === 'object' && error !== null && 'code' in error && error.code === 'auth/user-not-found') {
        throw new AppError('User not found', 404);
      }
      logger.error('Update user profile failed:', error);
      throw new AppError('Failed to update user profile', 500);
    }
  }

  // Create new user
  static async createUser(email: string, password: string, userData?: any) {
    try {
      const userRecord = await auth().createUser({
        email,
        password,
        displayName: userData?.displayName,
        photoURL: userData?.photoURL,
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
    } catch (error) {
      logger.error('Create user failed:', error);
      
      if (typeof error === 'object' && error !== null && 'code' in error) {
        const errorCode = (error as any).code;
        
        switch (errorCode) {
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
}