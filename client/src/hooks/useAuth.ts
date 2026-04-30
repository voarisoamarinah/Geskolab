import { useState } from 'react';
import api from '../api/axios';
import type { AuthResponse, LoginInput, User } from '../types/auth';

export const useAuth = () => {
    const [user, setUser] = useState<User | null>(() => {
        const saved = localStorage.getItem('user');
        try {
            return saved ? JSON.parse(saved) : null;
        } catch {
            return null;
        }
    });

    const login = async (data: LoginInput) => {
        const response = await api.post<AuthResponse>('/auth/login', data);
        const { token, user: userData } = response.data;

        localStorage.setItem('token', token);
        localStorage.setItem('user', JSON.stringify(userData));
        setUser(userData);
    };

    const logout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        setUser(null);
    };

    return { user, login, logout, isAuthenticated: !!user };
};