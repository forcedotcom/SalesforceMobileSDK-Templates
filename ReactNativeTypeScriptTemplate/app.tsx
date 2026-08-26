/*
 * Copyright (c) 2020-present, salesforce.com, inc.
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
 * Salesforce Mobile SDK React Native TypeScript Template
 *
 * This template demonstrates:
 * 1. Authenticating with Salesforce using the Mobile SDK
 * 2. Querying data from Salesforce using SOQL
 * 3. Displaying results in a mobile-friendly interface
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
import { oauth, net } from 'react-native-force';

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
// TypeScript Interfaces
// ===========================

/**
 * Salesforce SOQL query response structure
 */
interface QueryResponse {
    records: ContactRecord[];
    totalSize?: number;
}

/**
 * Contact record structure from Salesforce
 */
interface ContactRecord {
    Id: string;
    Name: string;
}

/**
 * Component props (navigation is provided by React Navigation)
 */
interface ContactListProps {
    navigation?: any;  // Navigation prop from Stack.Navigator
}

/**
 * Component state structure
 */
interface ContactListState {
    data: ContactRecord[];    // Array of contact records
    loading: boolean;         // Loading state indicator
    error: string | null;     // Error message if any
}

// ===========================
// Contact List Screen Component
// ===========================
/**
 * Main screen component that displays a list of Salesforce contacts.
 * Handles authentication, data fetching, and UI rendering.
 */
class ContactListScreen extends React.Component<ContactListProps, ContactListState> {
    constructor(props: ContactListProps) {
        super(props);
        console.log('Component constructor called');
        // Initialize component state
        this.state = {
            data: [],          // Array of contact records
            loading: true,     // Loading state indicator
            error: null,       // Error message if any
        };
    }

    // ===========================
    // Authentication
    // ===========================
    /**
     * Fetch data when the component mounts.
     *
     * NOTE: This template uses automatic authentication (shouldAuthenticate() returns true).
     * The Mobile SDK handles the OAuth flow automatically before the React Native app loads.
     * However, we need to wait for the activity to be available before making API calls.
     */
    componentDidMount() {
        console.log('Component mounted - setting up UI');

        // Set up logout button in navigation header
        this.props.navigation?.setOptions({
            headerRight: () => (
                <TouchableOpacity
                    style={styles.headerButton}
                    onPress={() => this.onLogout()}
                    activeOpacity={0.7}
                >
                    <Text style={styles.headerButtonText}>Logout</Text>
                </TouchableOpacity>
            )
        });

        // Wait for activity to be ready by checking credentials
        // This ensures the React Native bridge has the activity available before we make API calls
        console.log('Waiting for activity to be ready...');
        this.waitForActivityAndFetchData();
    }

    /**
     * Waits for the activity to be available, then checks authentication and fetches data.
     * The activity may not be immediately available when the component mounts,
     * so we wait 1 second before attempting authentication.
     */
    waitForActivityAndFetchData() {
        setTimeout(() => {
            oauth.getAuthCredentials(
                (credentials: any) => {
                    // Already logged in - fetch data immediately
                    console.log('Already authenticated - fetching data');
                    this.fetchData();
                },
                (error: any) => {
                    // Not logged in - trigger OAuth flow
                    console.log('Not authenticated - starting OAuth flow');
                    oauth.authenticate(
                        () => {
                            console.log('OAuth completed - fetching data');
                            this.fetchData();
                        },
                        (authError: any) => {
                            console.error('Authentication failed:', authError);
                            this.setState({
                                loading: false,
                                error: 'Authentication failed: ' + authError
                            });
                        }
                    );
                }
            );
        }, 1000);
    }

    // ===========================
    // Authentication Methods
    // ===========================

    /**
     * Logs out the user and clears contact data.
     * User will be prompted to log in again on next app launch.
     */
    onLogout() {
        console.log('Logout initiated');
        oauth.logout(() => {
            console.log('Logout completed - restarting authentication');
            this.setState({data: [], loading: true}, () => {
                // After logout, restart the authentication flow
                oauth.authenticate(
                    () => this.fetchData(),
                    (error: any) => {
                        console.error('Re-authentication failed:', error);
                        this.setState({
                            loading: false,
                            error: 'Unable to re-authenticate with Salesforce'
                        });
                    }
                );
            });
        });
    }

    // ===========================
    // Data Fetching
    // ===========================
    /**
     * Fetches contact records from Salesforce using a SOQL query.
     *
     * To customize:
     * - Change fields: Modify the SELECT clause
     * - Query different objects: Change 'Contact' to another SObject
     * - Add filters: Add a WHERE clause
     * - Change limit: Modify the LIMIT value
     */
    fetchData() {
        console.log('Fetching contacts from Salesforce');
        this.setState({ loading: true, error: null });

        // SOQL Query - customize this for your needs
        const soql = 'SELECT Id, Name FROM Contact ORDER BY Name LIMIT 100';

        net.query(
            soql,
            (response: QueryResponse) => {
                // Query succeeded
                console.log('Query succeeded - retrieved', response.totalSize, 'contacts');
                this.setState({
                    data: response.records || [],
                    loading: false,
                });
            },
            (error: any) => {
                // Query failed
                console.error('Query failed:', error);
                this.setState({
                    loading: false,
                    error: 'Failed to fetch contacts: ' + JSON.stringify(error),
                });
            }
        );
    }

    // ===========================
    // Render Functions
    // ===========================

    /**
     * Renders a single contact item with avatar and details.
     *
     * @param item - Contact record from Salesforce
     * @returns Contact list item component
     */
    renderContactItem = ({item}: {item: ContactRecord}): React.JSX.Element => {
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
     * @returns Loading indicator component
     */
    renderLoading(): React.JSX.Element {
        return (
            <View style={styles.centerContent}>
                <ActivityIndicator size="large" color={colors.sfBlue} />
                <Text style={styles.loadingText}>Loading contacts...</Text>
            </View>
        );
    }

    /**
     * Renders error message.
     *
     * @returns Error message component
     */
    renderError(): React.JSX.Element {
        return (
            <View style={styles.centerContent}>
                <Text style={styles.errorText}>{this.state.error}</Text>
            </View>
        );
    }

    /**
     * Renders empty state when no contacts are found.
     *
     * @returns Empty state component
     */
    renderEmpty(): React.JSX.Element {
        return (
            <View style={styles.centerContent}>
                <Text style={styles.emptyText}>No contacts found</Text>
            </View>
        );
    }

    /**
     * Main render method - determines which view to show based on state.
     *
     * @returns The component tree to render
     */
    render(): React.JSX.Element {
        const {data, loading, error} = this.state;

        // Show loading spinner while fetching data
        if (loading) {
            return this.renderLoading();
        }

        // Show error message if query failed
        if (error) {
            return this.renderError();
        }

        // Show empty state if no contacts found
        if (!data || data.length === 0) {
            return this.renderEmpty();
        }

        // Show contact list
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

    // Centered content (loading, error, empty states)
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

    // Error message text
    errorText: {
        fontSize: 16,
        color: colors.error,
        textAlign: 'center',
    },

    // Empty state text
    emptyText: {
        fontSize: 16,
        color: colors.textSecondary,
    },

    // Header button (Logout in navigation bar)
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
 * @returns Navigation container with app screens
 */
function App(): React.JSX.Element {
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

export default App;
