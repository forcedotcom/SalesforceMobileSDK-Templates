import React from 'react';
import {ActivityIndicator, Text, TouchableOpacity} from 'react-native';
import {act, create, ReactTestRenderer} from 'react-test-renderer';
import App from '../app';

const mockSetOptions = jest.fn();
const mockLogout = jest.fn();
const mockAuthenticate = jest.fn();
const mockGetAuthCredentials = jest.fn();
const mockQuery = jest.fn();

jest.mock('react-native-force', () => ({
    oauth: {
        logout: (...args: unknown[]) => mockLogout(...args),
        authenticate: (...args: unknown[]) => mockAuthenticate(...args),
        getAuthCredentials: (...args: unknown[]) => mockGetAuthCredentials(...args),
    },
    net: {query: (...args: unknown[]) => mockQuery(...args)},
}));

jest.mock('@react-navigation/native', () => ({
    NavigationContainer: ({children}: {children: React.ReactNode}) => children,
}));

jest.mock('@react-navigation/native-stack', () => ({
    createNativeStackNavigator: () => ({
        Navigator: ({children}: {children: React.ReactNode}) => children,
        Screen: ({component: Component}: {
            component: React.ComponentType<{
                navigation: {setOptions: typeof mockSetOptions};
            }>;
        }) => <Component navigation={{setOptions: mockSetOptions}} />,
    }),
}));

describe('Contacts logout', () => {
    let app: ReactTestRenderer;
    let header: ReactTestRenderer;

    beforeEach(() => {
        jest.useFakeTimers();
        jest.clearAllMocks();
        mockGetAuthCredentials.mockImplementation(success => success({}));
        mockQuery.mockImplementation((_query, success) => success({
            records: [{Id: 'fixture-contact', Name: 'Existing contact'}],
        }));
        act(() => {
            app = create(<App />);
        });
        act(() => {
            jest.runOnlyPendingTimers();
        });
        act(() => {
            header = create(mockSetOptions.mock.calls[0][0].headerRight());
        });
    });

    afterEach(() => {
        act(() => {
            app.unmount();
            header?.unmount();
        });
        jest.clearAllTimers();
        jest.useRealTimers();
    });

    function pressLogout() {
        act(() => {
            header.root.findByType(TouchableOpacity).props.onPress();
        });
    }

    it('shows a logout failure without starting another login', () => {
        pressLogout();
        const failure = mockLogout.mock.calls[0][1];
        expect(failure).toEqual(expect.any(Function));

        act(() => {
            failure({message: 'Logout failed'});
        });

        expect(mockAuthenticate).not.toHaveBeenCalled();
        expect(mockQuery).toHaveBeenCalledTimes(1);
        expect(app.root.findAllByType(ActivityIndicator)).toHaveLength(0);
        expect(app.root.findAllByType(Text).map(text => text.props.children))
            .toContain('Unable to log out of Salesforce. Please try again.');
    });

    it('waits for logout success before authenticating and fetching contacts', () => {
        expect(app.root.findAllByType(Text).map(text => text.props.children))
            .toContain('Existing contact');
        pressLogout();
        expect(mockAuthenticate).not.toHaveBeenCalled();

        act(() => {
            mockLogout.mock.calls[0][0]();
        });
        expect(mockAuthenticate).toHaveBeenCalledTimes(1);
        expect(mockQuery).toHaveBeenCalledTimes(1);
        expect(app.root.findAllByType(Text).map(text => text.props.children))
            .not.toContain('Existing contact');

        act(() => {
            mockAuthenticate.mock.calls[0][0]();
        });
        expect(mockQuery).toHaveBeenCalledTimes(2);
    });

    it('recovers from a failed logout when a later logout and login succeed', () => {
        pressLogout();
        act(() => {
            mockLogout.mock.calls[0][1]({message: 'Logout failed'});
        });
        expect(app.root.findAllByType(Text).map(text => text.props.children))
            .toContain('Unable to log out of Salesforce. Please try again.');

        pressLogout();
        act(() => {
            mockLogout.mock.calls[1][0]();
        });
        mockQuery.mockImplementation((_query, success) => success({
            records: [{Id: 'replacement-contact', Name: 'New contact'}],
        }));
        act(() => {
            mockAuthenticate.mock.calls[0][0]();
        });
        const text = app.root.findAllByType(Text).map(item => item.props.children);
        expect(text).toContain('New contact');
        expect(text).not.toContain('Existing contact');
        expect(text).not.toContain('Unable to log out of Salesforce. Please try again.');
        expect(app.root.findAllByType(ActivityIndicator)).toHaveLength(0);
    });

    it('shows a reauthentication failure after successful logout', () => {
        pressLogout();
        act(() => {
            mockLogout.mock.calls[0][0]();
        });
        act(() => {
            mockAuthenticate.mock.calls[0][1]({message: 'Login failed'});
        });

        expect(mockQuery).toHaveBeenCalledTimes(1);
        expect(app.root.findAllByType(ActivityIndicator)).toHaveLength(0);
        expect(app.root.findAllByType(Text).map(text => text.props.children))
            .toContain('Unable to re-authenticate with Salesforce');
    });
});
