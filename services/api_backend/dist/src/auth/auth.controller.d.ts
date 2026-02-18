import { AuthService } from './auth.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    register(dto: RegisterDto): Promise<import("./auth.service.js").AuthResponse>;
    login(dto: LoginDto): Promise<import("./auth.service.js").AuthResponse>;
    refresh(refreshToken: string): Promise<import("./auth.service.js").AuthTokens>;
    logout(_req: Express.Request): Promise<{
        message: string;
    }>;
}
