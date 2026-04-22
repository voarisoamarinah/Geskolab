import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import userRoutes from './routes/user.routes.js'; 

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/users', userRoutes); 

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Geskolab running on port ${PORT}`));