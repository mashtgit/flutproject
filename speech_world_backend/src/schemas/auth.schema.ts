import Joi from 'joi';

export const authSchema = {
  verifyToken: {
    body: Joi.object({
      token: Joi.string().required().description('Firebase ID token'),
    }),
  },
  
  createCustomToken: {
    body: Joi.object({
      uid: Joi.string().required().description('User ID'),
    }),
  },
  
  revokeTokens: {
    body: Joi.object({
      uid: Joi.string().required().description('User ID'),
    }),
  },
  
  setCustomClaims: {
    body: Joi.object({
      claims: Joi.object().required().description('Custom claims object'),
    }),
  },
  
  updateUserDisabled: {
    body: Joi.object({
      disabled: Joi.boolean().required().description('Disabled status'),
    }),
  },
};