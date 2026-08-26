/*
 * Copyright (c) 2023-present, salesforce.com, inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided
 * that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the
 * following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
 * the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or
 * promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Salesforce Mobile SDK React Native Deferred Authentication Template
 *
 * ===========================
 * DEFERRED AUTHENTICATION PATTERN
 * ===========================
 *
 * This template demonstrates DEFERRED (ON-DEMAND) AUTHENTICATION, which is different
 * from the standard Mobile SDK authentication pattern:
 *
 * STANDARD PATTERN (ReactNativeTemplate):
 * - App requires authentication IMMEDIATELY on startup
 * - OAuth flow starts automatically if user is not logged in
 * - User cannot use the app until they authenticate
 *
 * DEFERRED PATTERN (this template):
 * - App loads WITHOUT requiring authentication
 * - User sees a welcome screen and can explore the app as a "guest"
 * - Authentication only occurs when the user explicitly taps "Login"
 * - User can log out and continue using the app in guest mode
 *
 * HOW IT WORKS:
 * 1. componentDidMount() calls fetchData() immediately
 * 2. fetchData() attempts to query Salesforce (will fail if not authenticated)
 * 3. On failure, sets loggedIn: false - no error shown to user
 * 4. User sees welcome screen with Login button
 * 5. User taps Login → OAuth flow → fetchData() → contacts appear
 * 6. User can tap Logout → returns to welcome screen
 *
 * WHEN TO USE THIS PATTERN:
 * - Apps that want to show content to unauthenticated users
 * - "Try before you buy" experiences
 * - Apps with public content and authenticated features
 * - Progressive disclosure of functionality
 *
 * Customize by modifying the SOQL query and display logic below.
 */

import React from 'react';
import {
    StyleSheet,
    Text,
    View,
    FlatList,
    ActivityIndicator,
    TouchableOpacity,
    Platform,
} from 'react-native';

import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import {oauth, net} from 'react-native-force';

// ===========================
// Design Tokens
// ===========================
// Centralized color and spacing values for consistent design
const colors = {
    sfBlue: '#0176d3',
    background: '#f3f3f3',
    surface: '#ffffff',
    textPrimary: '#181818',
    textSecondary: '#706e6b',
    border: '#dddbda',
    error: '#c23934',
};

// ===========================
// Contact List Screen Component
// ===========================
/**
 * Main screen component with deferred authentication.
 * Handles login/logout, data fetching, and UI rendering.
 */
class ContactListScreen extends React.Component {
    constructor(props) {
        super(props);
        // Initialize component state
        this.state = {
            loggedIn: false,   // Authentication state
            data: [],          // Array of contact records
            loading: false,    // Loading state indicator
        };
    }

    // ===========================
    // Lifecycle Methods
    // ===========================

    /**
     * Called when component mounts.
     * Sets up the Login/Logout button and attempts to fetch data.
     *
     * IMPORTANT: This is where deferred authentication happens!
     * - fetchData() is called immediately, but it will fail silently if not authenticated
     * - No OAuth prompt appears - user remains in guest mode
     * - User must explicitly tap "Login" to authenticate
     */
    componentDidMount() {
        console.log("componentDidMount called");
        this.updateLoginLogout();
        // Try to fetch data - will succeed if already authenticated from a previous session,
        // fail silently otherwise (no error shown to user)
        this.fetchData();
    }

    /**
     * Called after component updates.
     * Updates the Login/Logout button in the header based on authentication state.
     */
    componentDidUpdate() {
        this.updateLoginLogout();
    }

    // ===========================
    // Navigation Header Management
    // ===========================

    /**
     * Updates the navigation header with Logout button (only when logged in).
     * Button changes dynamically based on authentication state:
     * - When loggedIn: false → No button shown (user uses centered Login button)
     * - When loggedIn: true → Shows "Logout" button in top right
     */
    updateLoginLogout() {
        this.props.navigation.setOptions({
            headerRight: () => this.state.loggedIn
                ? (
                    <TouchableOpacity
                        style={styles.headerButton}
                        onPress={() => this.onLogout()}
                        activeOpacity={0.7}
                    >
                        <Text style={styles.headerButtonText}>Logout</Text>
                    </TouchableOpacity>
                )
                : null  // No button when not logged in - user uses welcome screen button
        });
    }

    // ===========================
    // Data Fetching
    // ===========================

    /**
     * Fetches contact records from Salesforce using a SOQL query.
     *
     * DEFERRED AUTHENTICATION KEY CONCEPT:
     * This method is called immediately on componentDidMount(), but it does NOT
     * trigger OAuth authentication if the user is not logged in. Instead:
     * - If authenticated: Query succeeds, contacts are displayed
     * - If NOT authenticated: Query fails silently, loggedIn stays false
     *
     * This is the core of deferred authentication - the query failure is handled
     * gracefully without prompting the user to log in.
     *
     * To customize:
     * - Change fields: Modify the SELECT clause
     * - Query different objects: Change 'Contact' to another SObject
     * - Add filters: Add a WHERE clause
     * - Change limit: Modify the LIMIT value
     */
    fetchData() {
        console.log("fetchData called");
        // Note: We don't set loading: true here during initial check
        // to avoid showing a spinner before the user has even tried to login

        // SOQL Query - customize this for your needs
        net.query(
            'SELECT Id, Name FROM Contact ORDER BY Name LIMIT 100',
            (response) => {
                // Query succeeded - user is authenticated
                console.log("soql query completed - received " + (response.records ? response.records.length : 0) + " records");
                console.log("Setting state: loggedIn=true, data length=" + (response.records ? response.records.length : 0));
                this.setState({
                    loggedIn: true,
                    data: response.records || [],
                    loading: false,
                }, () => {
                    console.log("State updated: loggedIn=" + this.state.loggedIn + ", data count=" + this.state.data.length);
                });
            },
            (error) => {
                // Query failed - likely not authenticated yet
                // This is EXPECTED behavior for deferred authentication!
                // Do NOT show an error to the user - just stay in guest mode
                console.log("Query error: " + JSON.stringify(error));
                this.setState({
                    loggedIn: false,
                    data: [],
                    loading: false,
                });
            }
        );
    }

    // ===========================
    // Authentication Methods
    // ===========================

    /**
     * Initiates OAuth login flow when user taps "Login" button.
     * After successful login, fetches contact data.
     *
     * This is the ONLY place where OAuth authentication is triggered!
     * The user must explicitly request to log in.
     *
     * Note: We don't show a loading spinner here because the OAuth flow
     * will open a browser/webview for authentication. The loading spinner
     * will appear after authentication succeeds, during fetchData().
     */
    onLogin() {
        console.log("onLogin called");
        oauth.authenticate(
            () => {
                console.log("login completed - starting data fetch");
                // Show loading spinner while fetching data after successful auth
                this.setState({ loading: true }, () => {
                    console.log("Loading state set to true, calling fetchData");
                    this.fetchData();
                });
            },
            (error) => {
                console.error('login failed: ' + JSON.stringify(error));
            }
        );
    }

    /**
     * Logs out the user and clears contact data.
     * User returns to welcome screen and can continue using the app in guest mode.
     *
     * This is a key feature of deferred authentication - users can log out
     * without being forced to log back in immediately.
     */
    onLogout() {
        console.log("onLogout called");
        oauth.logout(() => {
            console.log("logout completed");
            this.setState({loggedIn: false, data: []});
        });
    }

    // ===========================
    // Render Functions
    // ===========================

    /**
     * Renders a single contact item with avatar and details.
     *
     * @param {Object} item - Contact record from Salesforce
     * @returns {JSX.Element} Contact list item component
     */
    renderContactItem = ({item}) => {
        const name = item.Name || 'Unknown';
        const initial = name.charAt(0).toUpperCase();

        return (
            <TouchableOpacity
                style={styles.contactItem}
                activeOpacity={0.7}
                onPress={() => console.log('Contact selected:', item.Id)}
            >
                {/* Contact Avatar - Circle with initial */}
                <View style={styles.contactAvatar}>
                    <Text style={styles.contactInitial}>{initial}</Text>
                </View>

                {/* Contact Details - Name and ID */}
                <View style={styles.contactDetails}>
                    <Text style={styles.contactName} numberOfLines={1}>
                        {name}
                    </Text>
                    <Text style={styles.contactId} numberOfLines={1}>
                        {item.Id}
                    </Text>
                </View>

                {/* Chevron indicator */}
                <Text style={styles.contactChevron}>›</Text>
            </TouchableOpacity>
        );
    };

    /**
     * Renders the loading state with spinner.
     *
     * @returns {JSX.Element} Loading indicator component
     */
    renderLoading() {
        return (
            <View style={styles.centerContent}>
                <ActivityIndicator size="large" color={colors.sfBlue} />
                <Text style={styles.loadingText}>Loading...</Text>
            </View>
        );
    }

    /**
     * Renders guest mode welcome screen when not logged in.
     * Shows a centered Login button for the user to start authentication.
     *
     * This is the key UX element for deferred authentication - a friendly
     * welcome screen that doesn't force the user to log in immediately.
     *
     * @returns {JSX.Element} Guest mode welcome screen component
     */
    renderWelcomeScreen() {
        return (
            <View style={styles.centerContent}>
                <View style={styles.welcomeCard}>
                    <Text style={styles.welcomeTitle}>Welcome!</Text>
                    <Text style={styles.welcomeText}>
                        This app demonstrates deferred authentication.
                    </Text>
                    <Text style={styles.welcomeText}>
                        Tap the button below to authenticate with Salesforce and view your contacts.
                    </Text>

                    {/* Centered Login Button */}
                    <TouchableOpacity
                        style={styles.loginButton}
                        onPress={() => this.onLogin()}
                        activeOpacity={0.8}
                    >
                        <Text style={styles.loginButtonText}>Login to Salesforce</Text>
                    </TouchableOpacity>
                </View>
            </View>
        );
    }

    /**
     * Renders empty state when logged in but no contacts are found.
     *
     * @returns {JSX.Element} Empty state component
     */
    renderEmptyState() {
        return (
            <View style={styles.centerContent}>
                <Text style={styles.emptyText}>No contacts found</Text>
            </View>
        );
    }

    /**
     * Main render method - determines which view to show based on state.
     *
     * Rendering logic for deferred authentication:
     * 1. If loading: Show spinner
     * 2. If NOT logged in: Show welcome screen with Login button
     * 3. If logged in but no data: Show empty state
     * 4. If logged in with data: Show contact list
     *
     * @returns {JSX.Element} The component tree to render
     */
    render() {
        const {data, loading, loggedIn} = this.state;

        // Show loading spinner while fetching data
        if (loading) {
            return this.renderLoading();
        }

        // Show welcome screen if not logged in (DEFERRED AUTHENTICATION)
        // This is the key difference from standard authentication - users
        // can use the app (see this screen) without being forced to log in
        if (!loggedIn) {
            return this.renderWelcomeScreen();
        }

        // Show empty state if logged in but no contacts found
        if (!data || data.length === 0) {
            return this.renderEmptyState();
        }

        // Show contact list (user is authenticated and has data)
        return (
            <View style={styles.container}>
                <FlatList
                    data={data}
                    renderItem={this.renderContactItem}
                    keyExtractor={(item, index) => item.Id || 'key_' + index}
                    contentContainerStyle={styles.listContent}
                />
            </View>
        );
    }
}

// ===========================
// Styles - Modern, clean design
// ===========================
const styles = StyleSheet.create({
    // Container for the entire screen
    container: {
        flex: 1,
        backgroundColor: colors.background,
    },

    // Content padding for the list
    listContent: {
        padding: 16,
    },

    // Individual contact item card
    contactItem: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: colors.surface,
        borderRadius: 8,
        padding: 12,
        marginBottom: 12,
        borderWidth: 1,
        borderColor: colors.border,
        // Shadow for iOS
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 1 },
        shadowOpacity: 0.1,
        shadowRadius: 3,
        // Shadow for Android
        elevation: 2,
    },

    // Circular avatar with gradient background
    contactAvatar: {
        width: 48,
        height: 48,
        borderRadius: 24,
        backgroundColor: colors.sfBlue,
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: 12,
    },

    // Initial letter in avatar
    contactInitial: {
        color: colors.surface,
        fontSize: 20,
        fontWeight: '600',
    },

    // Container for contact name and ID
    contactDetails: {
        flex: 1,
        marginRight: 8,
    },

    // Contact name text
    contactName: {
        fontSize: 16,
        fontWeight: '600',
        color: colors.textPrimary,
        marginBottom: 4,
    },

    // Contact ID text (monospace)
    contactId: {
        fontSize: 12,
        color: colors.textSecondary,
        fontFamily: 'Courier',
    },

    // Chevron indicator
    contactChevron: {
        fontSize: 24,
        color: colors.textSecondary,
    },

    // Centered content (loading, welcome, empty states)
    centerContent: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        padding: 40,
        backgroundColor: colors.background,
    },

    // Loading text below spinner
    loadingText: {
        marginTop: 16,
        fontSize: 16,
        color: colors.textSecondary,
    },

    // Welcome screen card
    welcomeCard: {
        backgroundColor: colors.surface,
        borderRadius: 12,
        padding: 32,
        alignItems: 'center',
        maxWidth: 400,
        borderWidth: 1,
        borderColor: colors.border,
        // Shadow for iOS
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
        // Shadow for Android
        elevation: 4,
    },

    // Welcome screen title
    welcomeTitle: {
        fontSize: 28,
        fontWeight: '600',
        color: colors.textPrimary,
        marginBottom: 20,
    },

    // Welcome screen body text
    welcomeText: {
        fontSize: 16,
        color: colors.textSecondary,
        textAlign: 'center',
        lineHeight: 24,
        marginBottom: 12,
    },

    // Centered login button
    loginButton: {
        backgroundColor: colors.sfBlue,
        borderRadius: 8,
        paddingVertical: 16,
        paddingHorizontal: 32,
        marginTop: 24,
        marginBottom: 16,
        minWidth: 200,
        // Shadow for iOS
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.2,
        shadowRadius: 4,
        // Shadow for Android
        elevation: 3,
    },

    // Login button text
    loginButtonText: {
        color: colors.surface,
        fontSize: 16,
        fontWeight: '600',
        textAlign: 'center',
    },

    // Empty state text
    emptyText: {
        fontSize: 16,
        color: colors.textSecondary,
    },

    // Header button (Login/Logout in navigation bar)
    // On iOS 26 the system adds a pill behind TouchableOpacity in headers — suppress our own pill there.
    headerButton: Platform.select({
        ios: {
            height: 44,
            marginRight: 4,
            alignItems: 'center',
            justifyContent: 'center',
            paddingHorizontal: 8,
        },
        android: {
            marginRight: 16,
            paddingVertical: 6,
            paddingHorizontal: 12,
            backgroundColor: 'rgba(255, 255, 255, 0.2)',
            borderRadius: 6,
            borderWidth: 1,
            borderColor: 'rgba(255, 255, 255, 0.4)',
        },
    }),

    // Header button text
    headerButtonText: {
        color: colors.surface,
        fontSize: 14,
        fontWeight: '600',
    },
});

// ===========================
// Navigation Setup
// ===========================
const Stack = createNativeStackNavigator();

/**
 * App root component with navigation container.
 * Configures the navigation stack with Salesforce blue header.
 *
 * The header includes a dynamic Login/Logout button managed by the
 * ContactListScreen component.
 *
 * @returns {JSX.Element} Navigation container with app screens
 */
export const App = function() {
    return (
        <NavigationContainer>
            <Stack.Navigator
                screenOptions={{
                    headerStyle: {
                        backgroundColor: colors.sfBlue,
                    },
                    headerTintColor: colors.surface,
                    headerTitleStyle: {
                        fontWeight: '600',
                    },
                    statusBarTranslucent: true,
                    statusBarColor: colors.sfBlue,
                    statusBarStyle: 'light',
                }}
            >
                <Stack.Screen
                    name="Contacts"
                    component={ContactListScreen}
                />
            </Stack.Navigator>
        </NavigationContainer>
    );
}
