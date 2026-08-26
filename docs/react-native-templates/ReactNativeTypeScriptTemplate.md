# ReactNativeTypeScriptTemplate

The TypeScript React Native template for Salesforce Mobile SDK applications.

> **API style note:** The `react-native-force` SDK uses callback-based APIs (`fn(args, successCallback, errorCallback)`). Promise-style code in this guide is illustrative; use `forceUtil.promiser(fn)` for actual promise wrappers.

## Overview

`ReactNativeTypeScriptTemplate` is the TypeScript version of the basic React Native template. It provides:

- **TypeScript** with full type safety and IDE support
- **Immediate authentication** on app launch
- **Cross-platform** support (iOS and Android)
- **Sample SOQL query** with typed responses
- **React Navigation** with TypeScript navigation types
- **Mobile SDK integration** with `react-native-force`

## When to Use This Template

Choose `ReactNativeTypeScriptTemplate` if:

- You want TypeScript's type safety and developer experience
- You're building a large-scale application
- Your team prefers strongly-typed code
- You need better IDE autocomplete and refactoring
- You want to catch errors at compile-time rather than runtime
- Your app requires users to authenticate before accessing any features

## Not the Right Fit?

- **Prefer JavaScript?** → Use [ReactNativeTemplate](./ReactNativeTemplate.md)
- **Need guest mode?** → Use [ReactNativeDeferredTemplate](./ReactNativeDeferredTemplate.md) (JavaScript only)
- **Learning the SDK?** → Use [MobileSyncExplorerReactNative](./MobileSyncExplorerReactNative.md) (JavaScript only)

## Creating an App from This Template

### Using the CLI

```bash
forcereact create \
  --appname MyApp \
  --packagename com.mycompany.myapp \
  --organization "My Company" \
  --templatename ReactNativeTypeScriptTemplate
```

### With OAuth Configuration

```bash
forcereact create \
  --appname MyApp \
  --packagename com.mycompany.myapp \
  --organization "My Company" \
  --templatename ReactNativeTypeScriptTemplate \
  --consumerkey "3MVG9..." \
  --callbackurl "myapp://oauth/callback"
```

## Differences from JavaScript Template

| Feature | ReactNativeTemplate | ReactNativeTypeScriptTemplate |
|---------|---------------------|-------------------------------|
| Language | JavaScript (`.js`) | TypeScript (`.tsx`) |
| Type Checking | Runtime only | Compile-time + Runtime |
| IDE Support | Basic | Advanced (autocomplete, refactoring) |
| Error Detection | Runtime errors | Compile-time errors |
| Interfaces/Types | None | Fully typed |
| Build Step | Babel only | TypeScript compiler + Babel |
| Learning Curve | Lower | Higher |
| Maintenance | Good | Better (type safety prevents bugs) |

## Project Structure

```
MyApp/
├── package.json                 # Dependencies and SDK references
├── app.tsx                      # Main application code (TypeScript)
├── index.js                     # React Native entry point
├── tsconfig.json                # TypeScript compiler configuration
├── metro.config.js              # Metro bundler configuration
├── babel.config.js              # Babel configuration
├── .eslintrc.js                 # ESLint rules (with TS support)
├── mobile_sdk/                  # Cloned SDK repositories (gitignored)
│   ├── SalesforceMobileSDK-iOS/
│   └── SalesforceMobileSDK-Android/
├── ios/                         # iOS native project (same as JS template)
└── android/                     # Android native project (same as JS template)
```

## Key Files

### app.tsx

The main application code with TypeScript types.

**Default implementation:**

```typescript
import React from 'react';
import {
    StyleSheet,
    Text,
    View,
    FlatList,
    ActivityIndicator,
    TouchableOpacity,
} from 'react-native';

import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { oauth, net } from 'react-native-force';

// Define navigation types
type RootStackParamList = {
  Home: undefined;
  Details: { recordId: string };
};

const Stack = createNativeStackNavigator<RootStackParamList>();

// Define data types
interface SalesforceRecord {
  Id: string;
  Name: string;
  attributes: {
    type: string;
    url: string;
  };
}

interface AppState {
  authenticated: boolean;
  records: SalesforceRecord[];
  loading: boolean;
}

export default class App extends React.Component<{}, AppState> {
  state: AppState = {
    authenticated: false,
    records: [],
    loading: true
  };

  componentDidMount(): void {
    this.authenticate();
  }

  authenticate = async (): Promise<void> => {
    try {
      const credentials = await oauth.getAuthCredentials();
      this.setState({ authenticated: true });
      await this.fetchData();
    } catch (error) {
      console.error('Authentication error:', error);
      this.setState({ loading: false });
    }
  }

  fetchData = async (): Promise<void> => {
    try {
      const response = await net.query('SELECT Id, Name FROM Account LIMIT 10');
      this.setState({ 
        records: response.records as SalesforceRecord[],
        loading: false 
      });
    } catch (error) {
      console.error('Query error:', error);
      this.setState({ loading: false });
    }
  }

  render() {
    return (
      <NavigationContainer>
        <Stack.Navigator>
          <Stack.Screen name="Home" component={HomeScreen} />
          <Stack.Screen name="Details" component={DetailsScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    );
  }
}
```

**Key TypeScript features:**

- `type RootStackParamList` - Type-safe navigation
- `interface SalesforceRecord` - Typed Salesforce data
- `interface AppState` - Typed component state
- `async/await` with return type annotations
- Type assertion for API responses

### tsconfig.json

TypeScript compiler configuration.

```json
{
  "extends": "@react-native/typescript-config/tsconfig.json",
  "compilerOptions": {
    "allowSyntheticDefaultImports": true,
    "jsx": "react-native",
    "lib": ["es2017"],
    "moduleResolution": "node",
    "noEmit": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "strict": true,
    "target": "esnext"
  },
  "exclude": [
    "node_modules",
    "babel.config.js",
    "metro.config.js",
    "jest.config.js"
  ]
}
```

**Key options:**

- `strict: true` - Enable all strict type-checking options
- `noEmit: true` - Don't emit JS files (Babel handles transpilation)
- `skipLibCheck: true` - Skip type checking of declaration files
- `resolveJsonModule: true` - Import JSON files with types

## TypeScript Features

### Type-Safe Navigation

Define navigation types for type-safe screen navigation:

```typescript
import { NativeStackScreenProps } from '@react-navigation/native-stack';

type RootStackParamList = {
  Home: undefined;
  Details: { recordId: string; name: string };
  Edit: { recordId: string };
};

// Use in screen components
type DetailsScreenProps = NativeStackScreenProps<RootStackParamList, 'Details'>;

function DetailsScreen({ route, navigation }: DetailsScreenProps) {
  const { recordId, name } = route.params; // Fully typed!
  
  return (
    <View>
      <Text>Record: {name}</Text>
      <Button
        title="Edit"
        onPress={() => navigation.navigate('Edit', { recordId })}
      />
    </View>
  );
}
```

**Benefits:**

- Autocomplete for screen names
- Type-checked route parameters
- Compile-time errors for invalid navigation

### Typed Salesforce Responses

Define interfaces for Salesforce data:

```typescript
interface Account {
  Id: string;
  Name: string;
  Industry?: string;
  AnnualRevenue?: number;
  attributes: {
    type: 'Account';
    url: string;
  };
}

interface Contact {
  Id: string;
  FirstName?: string;
  LastName: string;
  Email?: string;
  AccountId?: string;
  attributes: {
    type: 'Contact';
    url: string;
  };
}

// Use with SOQL queries
async function fetchAccounts(): Promise<Account[]> {
  const response = await net.query<{ records: Account[] }>(
    'SELECT Id, Name, Industry, AnnualRevenue FROM Account LIMIT 10'
  );
  return response.records;
}

async function fetchContacts(): Promise<Contact[]> {
  const response = await net.query<{ records: Contact[] }>(
    'SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 10'
  );
  return response.records;
}
```

**Benefits:**

- Autocomplete for record fields
- Type errors for misspelled fields
- Null safety for optional fields

### Typed SmartStore Operations

Type-safe offline storage:

```typescript
import { smartstore } from 'react-native-force';

interface ContactSoupEntry {
  _soupEntryId: number;
  Id: string;
  FirstName: string;
  LastName: string;
  Email?: string;
  __local__: boolean;
  __locally_created__: boolean;
  __locally_updated__: boolean;
  __locally_deleted__: boolean;
}

async function saveContacts(contacts: Contact[]): Promise<void> {
  const soupEntries: ContactSoupEntry[] = contacts.map((contact, index) => ({
    _soupEntryId: index + 1,
    ...contact,
    __local__: false,
    __locally_created__: false,
    __locally_updated__: false,
    __locally_deleted__: false,
  }));

  await smartstore.upsertSoupEntries(
    false,
    'contacts',
    soupEntries
  );
}

async function queryContacts(): Promise<ContactSoupEntry[]> {
  const result = await smartstore.querySoup(
    false,
    'contacts',
    { queryType: 'range', indexPath: 'LastName', order: 'ascending' }
  );
  return result.currentPageOrderedEntries as ContactSoupEntry[];
}
```

### Typed React Hooks

Use TypeScript with React Hooks:

```typescript
import React, { useState, useEffect } from 'react';

function ContactList() {
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    fetchContacts()
      .then(setContacts)
      .catch(setError)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <ActivityIndicator />;
  if (error) return <Text>Error: {error.message}</Text>;

  return (
    <FlatList
      data={contacts}
      keyExtractor={item => item.Id}
      renderItem={({ item }) => (
        <Text>{item.FirstName} {item.LastName}</Text>
      )}
    />
  );
}
```

### Typed Props and State

Type-safe component props and state:

```typescript
interface ContactCardProps {
  contact: Contact;
  onPress: (contactId: string) => void;
  showEmail?: boolean;
}

interface ContactCardState {
  expanded: boolean;
}

class ContactCard extends React.Component<ContactCardProps, ContactCardState> {
  state: ContactCardState = {
    expanded: false
  };

  static defaultProps = {
    showEmail: true
  };

  handlePress = () => {
    this.props.onPress(this.props.contact.Id);
  }

  toggleExpanded = () => {
    this.setState(prevState => ({ expanded: !prevState.expanded }));
  }

  render() {
    const { contact, showEmail } = this.props;
    const { expanded } = this.state;

    return (
      <TouchableOpacity onPress={this.handlePress}>
        <Text>{contact.FirstName} {contact.LastName}</Text>
        {showEmail && <Text>{contact.Email}</Text>}
      </TouchableOpacity>
    );
  }
}
```

## Type Definitions for react-native-force

The `react-native-force` package ships its own TypeScript definitions (`dist/index.d.ts` generated from `src/`). Important types to know:

- **`UserAccount`** (from `react-native-force/dist/typings/oauth`):
  ```typescript
  type UserAccount = {
    accessToken: string;
    clientId: string;
    instanceUrl: string;
    loginUrl: string;
    orgId: string;
    refreshToken: string;
    userAgent: string;
    userId: string;
  };
  ```
- **`SyncDownTarget`, `SyncUpTarget`, `SyncOptions`, `SyncStatus`, `SyncEvent`** from `react-native-force/dist/typings/mobilesync`
- **`HttpMethod`, `LogLevel`, `QuerySpecType`, `StoreOrder`** from `react-native-force/dist/typings`
- **`ExecSuccessCallback<T>`, `ExecErrorCallback`** for callback typing

**The SDK uses callback-based APIs**, not Promises:

```typescript
import { oauth, net, forceUtil } from 'react-native-force';
import type { UserAccount } from 'react-native-force/dist/typings/oauth';

oauth.getAuthCredentials(
  (creds: UserAccount) => { /* ... */ },
  (err: Error) => { /* ... */ }
);

// Promise-style: wrap with forceUtil.promiser
const getAuth = forceUtil.promiser(oauth.getAuthCredentials);
const creds: UserAccount = await getAuth();
```

If you prefer additional types not exported by the package, you can add a `types/` folder to your project and write your own `.d.ts` declarations. **Do not redeclare the package's types** — that would mask the bundled definitions.

## Running the App

### Development

```bash
# Install dependencies
npm install
cd ios && pod install && cd ..

# Type-check (run this often during development)
npx tsc --noEmit

# Start Metro bundler
npm start

# Run on iOS
npm run ios

# Run on Android
npm run android
```

### Type Checking

```bash
# Check for type errors
npx tsc --noEmit

# Watch mode (continuous type checking)
npx tsc --noEmit --watch
```

### Linting

```bash
# Run ESLint with TypeScript support
npm run lint

# Auto-fix issues
npm run lint -- --fix
```

## Customization Guide

### Adding a Typed Screen Component

```typescript
import React, { useState, useEffect } from 'react';
import { View, Text, FlatList, StyleSheet } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { net } from 'react-native-force';

// Define navigation types
type RootStackParamList = {
  Home: undefined;
  AccountList: undefined;
  AccountDetails: { accountId: string };
};

type Props = NativeStackScreenProps<RootStackParamList, 'AccountList'>;

// Define data types
interface Account {
  Id: string;
  Name: string;
  Industry?: string;
  attributes: { type: 'Account'; url: string };
}

export default function AccountListScreen({ navigation }: Props) {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    loadAccounts();
  }, []);

  async function loadAccounts(): Promise<void> {
    try {
      const response = await net.query<{ records: Account[] }>(
        'SELECT Id, Name, Industry FROM Account ORDER BY Name LIMIT 50'
      );
      setAccounts(response.records);
    } catch (error) {
      console.error('Error loading accounts:', error);
    } finally {
      setLoading(false);
    }
  }

  return (
    <View style={styles.container}>
      {loading ? (
        <Text>Loading...</Text>
      ) : (
        <FlatList
          data={accounts}
          keyExtractor={item => item.Id}
          renderItem={({ item }) => (
            <TouchableOpacity
              onPress={() => navigation.navigate('AccountDetails', { accountId: item.Id })}
            >
              <Text style={styles.name}>{item.Name}</Text>
              {item.Industry && <Text style={styles.industry}>{item.Industry}</Text>}
            </TouchableOpacity>
          )}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16 },
  name: { fontSize: 18, fontWeight: 'bold' },
  industry: { fontSize: 14, color: '#666' }
});
```

### Creating Type-Safe API Helpers

```typescript
// api.ts
import { net } from 'react-native-force';

export interface Account {
  Id: string;
  Name: string;
  Industry?: string;
  AnnualRevenue?: number;
}

export interface Contact {
  Id: string;
  FirstName?: string;
  LastName: string;
  Email?: string;
  AccountId?: string;
}

export class SalesforceAPI {
  static async getAccounts(limit: number = 10): Promise<Account[]> {
    const response = await net.query<{ records: Account[] }>(
      `SELECT Id, Name, Industry, AnnualRevenue FROM Account LIMIT ${limit}`
    );
    return response.records;
  }

  static async getAccount(id: string): Promise<Account> {
    return await net.retrieve('Account', id, ['Id', 'Name', 'Industry', 'AnnualRevenue']);
  }

  static async createAccount(fields: Partial<Account>): Promise<string> {
    const result = await net.create('Account', fields);
    return result.id;
  }

  static async updateAccount(id: string, fields: Partial<Account>): Promise<void> {
    await net.update('Account', id, fields);
  }

  static async deleteAccount(id: string): Promise<void> {
    await net.del('Account', id);
  }

  static async getContactsForAccount(accountId: string): Promise<Contact[]> {
    const response = await net.query<{ records: Contact[] }>(
      `SELECT Id, FirstName, LastName, Email FROM Contact WHERE AccountId = '${accountId}'`
    );
    return response.records;
  }
}

// Usage in components
import { SalesforceAPI, Account } from './api';

async function loadData() {
  const accounts: Account[] = await SalesforceAPI.getAccounts(20);
  const account: Account = await SalesforceAPI.getAccount('001...');
  const newId: string = await SalesforceAPI.createAccount({ Name: 'Acme Corp' });
}
```

### Type-Safe Context API

```typescript
import React, { createContext, useContext, useState, ReactNode } from 'react';
import { oauth } from 'react-native-force';

interface AuthContextValue {
  authenticated: boolean;
  credentials: oauth.Credentials | null;
  login: () => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [authenticated, setAuthenticated] = useState(false);
  const [credentials, setCredentials] = useState<oauth.Credentials | null>(null);

  async function login() {
    try {
      const creds = await oauth.authenticate();
      setCredentials(creds);
      setAuthenticated(true);
    } catch (error) {
      console.error('Login failed:', error);
    }
  }

  function logout() {
    oauth.logout();
    setAuthenticated(false);
    setCredentials(null);
  }

  return (
    <AuthContext.Provider value={{ authenticated, credentials, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}

// Usage in components
function MyComponent() {
  const { authenticated, credentials, logout } = useAuth();

  return (
    <View>
      <Text>User: {credentials?.userId}</Text>
      <Button title="Logout" onPress={logout} />
    </View>
  );
}
```

## Common TypeScript Patterns

### Discriminated Unions for Loading States

```typescript
type LoadingState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };

function DataComponent() {
  const [state, setState] = useState<LoadingState<Account[]>>({ status: 'idle' });

  useEffect(() => {
    setState({ status: 'loading' });
    SalesforceAPI.getAccounts()
      .then(data => setState({ status: 'success', data }))
      .catch(error => setState({ status: 'error', error }));
  }, []);

  switch (state.status) {
    case 'idle':
      return <Text>Ready to load</Text>;
    case 'loading':
      return <ActivityIndicator />;
    case 'success':
      return <FlatList data={state.data} />;
    case 'error':
      return <Text>Error: {state.error.message}</Text>;
  }
}
```

### Generic Components

```typescript
interface ListProps<T> {
  items: T[];
  keyExtractor: (item: T) => string;
  renderItem: (item: T) => React.ReactElement;
}

function GenericList<T>({ items, keyExtractor, renderItem }: ListProps<T>) {
  return (
    <FlatList
      data={items}
      keyExtractor={keyExtractor}
      renderItem={({ item }) => renderItem(item)}
    />
  );
}

// Usage
<GenericList<Account>
  items={accounts}
  keyExtractor={account => account.Id}
  renderItem={account => <Text>{account.Name}</Text>}
/>
```

## TypeScript Best Practices

1. **Enable strict mode** in `tsconfig.json`
2. **Avoid `any`** - Use `unknown` or specific types
3. **Use interfaces for objects** - More readable than inline types
4. **Export types** - Share types across files
5. **Type API responses** - Don't trust external data
6. **Use readonly** for immutable data
7. **Leverage type guards** for runtime checks

```typescript
// Type guard example
function isContact(record: any): record is Contact {
  return record && typeof record.LastName === 'string';
}

// Usage
if (isContact(data)) {
  console.log(data.LastName); // TypeScript knows this is a Contact
}
```

## Testing

### Type-Safe Tests

```typescript
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import AccountListScreen from './AccountListScreen';

describe('AccountListScreen', () => {
  it('loads and displays accounts', async () => {
    const { getByText } = render(<AccountListScreen />);
    
    await waitFor(() => {
      expect(getByText('Acme Corp')).toBeTruthy();
    });
  });
});
```

## Troubleshooting

### Type Errors in react-native-force

If you see type errors from `react-native-force`, you may need to augment the type definitions:

```typescript
// types/react-native-force.d.ts
declare module 'react-native-force' {
  export namespace oauth {
    interface Credentials {
      // Add any missing properties here
      customField?: string;
    }
  }
}
```

### Module Resolution Errors

Add path aliases to `tsconfig.json`:

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@components/*": ["./src/components/*"],
      "@api/*": ["./src/api/*"]
    }
  }
}
```

## Next Steps

- Read [TEMPLATE_ANATOMY.md](./TEMPLATE_ANATOMY.md) for template internals
- Review [ReactNativeTemplate.md](./ReactNativeTemplate.md) for non-TypeScript version
- Check [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/)
- Explore [React TypeScript Cheatsheet](https://react-typescript-cheatsheet.netlify.app/)

## Related Resources

- [TypeScript Documentation](https://www.typescriptlang.org/)
- [React Native TypeScript](https://reactnative.dev/docs/typescript)
- [React Navigation TypeScript](https://reactnavigation.org/docs/typescript/)
- [Salesforce Mobile SDK Documentation](https://developer.salesforce.com/docs/platform/mobile-sdk/guide)
