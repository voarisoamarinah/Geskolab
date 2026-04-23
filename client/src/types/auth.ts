export interface User {
    id: number;
    username: string;
    role: string;
}

export interface AuthResponse {
    token: string;
    user: User;
}

export interface LoginInput {
    username: string;
    password: string;
}