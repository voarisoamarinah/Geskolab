import { Router } from 'express';
import * as UserCtrl from '../controllers/user.controller.js';
import validate from '../middlewares/validateResource.js';
import { createUser, queryUser, updateUser, userId } from '../validations/user.validation.js';
import { requireAuth, requireRole } from '../middlewares/auth.middleware.js';

const router = Router();

router.get('/', requireAuth, validate(queryUser), UserCtrl.getUsersHandler);
router.get('/:id', requireAuth, validate(userId), UserCtrl.getUserByIdHandler);
router.post('/', requireAuth, requireRole('ADMIN'), validate(createUser), UserCtrl.createUserHandler);
router.patch('/:id', requireAuth, validate(updateUser), UserCtrl.updateUserHandler);
router.delete('/:id', requireAuth, requireRole('ADMIN'), validate(userId), UserCtrl.deleteUserHandler);

export default router;