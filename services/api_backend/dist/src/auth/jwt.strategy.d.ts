import { Strategy } from 'passport-jwt';
import { AuthService } from './auth.service.js';
interface JwtPayload {
    sub: string;
    email: string;
    iat: number;
    exp: number;
}
declare const JwtStrategy_base: new (...args: [opt: import("passport-jwt").StrategyOptionsWithRequest] | [opt: import("passport-jwt").StrategyOptionsWithoutRequest]) => Strategy & {
    validate(...args: any[]): unknown;
};
export declare class JwtStrategy extends JwtStrategy_base {
    private readonly authService;
    constructor(authService: AuthService);
    validate(payload: JwtPayload): Promise<{
        id: string;
        email: string;
        role: string;
    }>;
}
export {};
