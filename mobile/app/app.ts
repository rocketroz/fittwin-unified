/**
 * FitTwin Platform - NativeScript App Entry Point
 * 
 * This is the main entry point for the NativeScript mobile application.
 * It initializes the app, sets up navigation, and configures platform-specific features.
 */

import { Application } from '@nativescript/core';
import { setupServices } from './core/services';
import { initializeApp } from './core/init';

// Initialize core services
setupServices();

// Initialize app configuration
initializeApp();

// Start the application
Application.run({ moduleName: 'app-root' });
