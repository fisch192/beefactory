import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
export interface TokenPayload {
    sub: string;
    email: string;
}
export interface AuthTokens {
    accessToken: string;
    refreshToken: string;
}
export interface AuthResponse extends AuthTokens {
    user: {
        id: string;
        email: string;
        displayName: string | null;
        role: string;
    };
}
export declare class AuthService {
    private readonly prisma;
    private readonly jwtService;
    constructor(prisma: PrismaService, jwtService: JwtService);
    register(dto: RegisterDto): Promise<AuthResponse>;
    login(dto: LoginDto): Promise<AuthResponse>;
    refresh(refreshToken: string): Promise<AuthTokens>;
    logout(): Promise<{
        message: string;
    }>;
    validateUser(payload: TokenPayload): Promise<{
        id: string;
        email: string;
        role: string;
    } | null>;
    private generateTokens;
}
