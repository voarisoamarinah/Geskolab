import { Router } from 'express';
import { createUserHandler } from '../controllers/user.controller.js';
import validate from '../middlewares/validateResource.js';
import { createUser } from '../validations/user.validation.js';

const router = Router();

router.post('/', validate(createUser), createUserHandler);

export default router;