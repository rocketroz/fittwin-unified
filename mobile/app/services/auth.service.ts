/**
 * Authentication Service
 * 
 * Handles user authentication, token management, and session persistence.
 */

import { ApiClient } from '@shared/api-client';
import { ApplicationSettings } from '@nativescript/core';

export interface User {
  id: string;
  email: string;
  name?: string;
  role: 'shopper' | 'brand' | 'admin';
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
}

export class AuthService {
  private static readonly TOKEN_KEY = 'auth_tokens';
  private static readonly USER_KEY = 'user_data';

  constructor(private apiClient: ApiClient) {
    this.loadStoredAuth();
  }

  /**
   * Sign up new user
   */
  async signup(email: string, password: string, name?: string): Promise<User> {
    try {
      const response = await this.apiClient.post('/auth/signup', {
        email,
        password,
        name
      });

      const { user, tokens } = response.data;
      this.storeAuth(user, tokens);
      return user;
    } catch (error) {
      console.error('Signup failed:', error);
      throw error;
    }
  }

  /**
   * Sign in existing user
   */
  async signin(email: string, password: string): Promise<User> {
    try {
      const response = await this.apiClient.post('/auth/signin', {
        email,
        password
      });

      const { user, tokens } = response.data;
      this.storeAuth(user, tokens);
      return user;
    } catch (error) {
      console.error('Signin failed:', error);
      throw error;
    }
  }

  /**
   * Sign out current user
   */
  async signout(): Promise<void> {
    try {
      await this.apiClient.post('/auth/signout');
    } catch (error) {
      console.error('Signout failed:', error);
    } finally {
      this.clearAuth();
    }
  }

  /**
   * Get current user
   */
  getCurrentUser(): User | null {
    const userData = ApplicationSettings.getString(AuthService.USER_KEY);
    return userData ? JSON.parse(userData) : null;
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    const tokens = this.getStoredTokens();
    if (!tokens) return false;

    // Check if token is expired
    return Date.now() < tokens.expiresAt;
  }

  /**
   * Get stored auth tokens
   */
  private getStoredTokens(): AuthTokens | null {
    const tokensData = ApplicationSettings.getString(AuthService.TOKEN_KEY);
    return tokensData ? JSON.parse(tokensData) : null;
  }

  /**
   * Store authentication data
   */
  private storeAuth(user: User, tokens: AuthTokens): void {
    ApplicationSettings.setString(AuthService.USER_KEY, JSON.stringify(user));
    ApplicationSettings.setString(AuthService.TOKEN_KEY, JSON.stringify(tokens));
    
    // Set token in API client
    this.apiClient.setAuthToken(tokens.accessToken);
  }

  /**
   * Clear authentication data
   */
  private clearAuth(): void {
    ApplicationSettings.remove(AuthService.USER_KEY);
    ApplicationSettings.remove(AuthService.TOKEN_KEY);
    this.apiClient.setAuthToken(null);
  }

  /**
   * Load stored authentication on service initialization
   */
  private loadStoredAuth(): void {
    const tokens = this.getStoredTokens();
    if (tokens && Date.now() < tokens.expiresAt) {
      this.apiClient.setAuthToken(tokens.accessToken);
    }
  }
}
