import { Router } from 'express';
import * as UserCtrl from '../controllers/user.controller.js';
import validate from '../middlewares/validateResource.js';
import { createUser, updateUser, userId } from '../validations/user.validation.js';

const router = Router();

router.get('/', UserCtrl.getUsersHandler);

router.get('/:id', validate(userId), UserCtrl.getUserByIdHandler);

router.post('/', validate(createUser), UserCtrl.createUserHandler);

router.patch('/:id', validate(updateUser), UserCtrl.updateUserHandler);

router.delete('/:id', validate(userId), UserCtrl.deleteUserHandler);

export default router;