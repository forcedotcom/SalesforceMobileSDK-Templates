# MobileSyncExplorerKotlinTemplate

An Android native template app demonstrating use of Salesforce's Mobile SDK with modern Android
architecture such as Jetpack Compose and support for flexible UI.

## Introduction

Welcome to the MobileSync Explorer Kotlin Template! This template demonstrates how to create a
custom Android native app to integrate seamlessly with Salesforce using Mobile SDK. You are
encouraged to use this template as a starting point and adapt it for your app's use-cases.

Some key features are:

- Full support for Kotlin Coroutines with all MSDK data operations
- UI designed for flexible layouts using Jetpack Compose
- An extensible solution for bridging between Salesforce Object JSON and Kotlin data classes
- All written in Kotlin!

The discussion herein assumes familiarity with both modern Android architecture and the Salesforce
MSDK.

## MobileSync With Modern Android Architecture

The power of Salesforce's MSDK and MobileSync is in the ease of handling synchronizing records to
and from your Org. The details of Sync Target runs should not be a concern of the UI layer of your
application, and thankfully it is very easy to encapsulate these sync operations in the data layer
of your app.  The most common data layer pattern is the implementation of Repositories, or "Repos."

### `SObjectSyncableRepo`

The core of this template's data layer API is the `SObjectSyncableRepo` interface:

```kotlin
interface SObjectSyncableRepo<T : SObject> {
    val recordsById: Flow<Map<String, SObjectRecord<T>>>

    @Throws(
        SyncDownException::class,
        RepoOperationException.SmartStoreOperationFailed::class,
    )
    suspend fun syncDown()

    @Throws(SyncUpException::class)
    suspend fun syncUp()

    @Throws(RepoOperationException::class)
    suspend fun locallyUpdate(id: String, so: T): SObjectRecord<T>

    @Throws(RepoOperationException::class)
    suspend fun locallyCreate(so: T): SObjectRecord<T>

    @Throws(RepoOperationException::class)
    suspend fun locallyDelete(id: String): SObjectRecord<T>?

    @Throws(RepoOperationException::class)
    suspend fun locallyUndelete(id: String): SObjectRecord<T>

    @Throws(RepoOperationException.SmartStoreOperationFailed::class)
    suspend fun refreshRecordsListFromSmartStore()
}
```

There are three important parts to this interface:

 1. SObject Sync Up and Sync Down operations
 1. SObject local modifications (e.g. creating a new record)
 1. A Kotlin Flow of records that your app can collect to reactively update app state

The design of this API creates a single source of truth for a SObject's records in both your local
device and "upstream" records downloaded from your Org.

All interface methods and properties are built on Kotlin Coroutines, so you can leverage Android's
recommended framework for asynchronous operations. Your ViewModel code could look something like
this:

```kotlin
/**
 * A View Model for a component which shows a list of Contacts. Implementation is vastly simplified
 * in this README for illustrative purposes.
 */
class ContactsListViewModel : ViewModel() {
    // initialization of these class members is not shown

    private val repo: SObjectSyncableRepo<ContactObject>
    private val mutUiState: MutableStateFlow<UiState>
    val uiState: StateFlow<UiState> get() = mutUiState

    init {
        // Records collector reacting to repo updates:
        viewModelScope.launch {
            repo.recordsById.collect { recordsById ->
                mutUiState.value = uiState.value.copy(recordsList = recordsById.values)
            }
        }
    }

    fun onSyncClick() {
        viewModelScope.launch {
            try {
                mutUiState.value = uiState.value.copy(isSyncing = true)
                repo.syncDown() // suspending
            } catch (ex: SyncDownException) {
                // Inform user of sync run error
            } catch (ex: RepoOperationException.SmartStoreOperationFailed) {
                // Inform user of sync run error
            } finally {
                mutUiState.value = uiState.value.copy(isSyncing = false)
            }

            // Records collector will now get an emission of the records synced down from the Org
        }
    }
}
```

Here you see how using the `SObjectSyncableRepo` allows for fluent and reactive logic in the UI
layer.

### Related Records in v1.0 of This Template

The `SObjectSyncableRepo` is meant to be for a _single_ SObject without related records. The
semantics for sync operations with related records do not work with this interface, and you are
encouraged to adapt this template to fit your needs. A future version of this template may introduce
related record handling out-of-the-box.

## SObjects, JSONs, and Data Classes

Salesforce is fundamentally built on representing SObjects as JSONs. This flexible data structure
enables the level of customization unique to Salesforce, but it also creates many headaches when
working with them in Android. JSON's flexibility circumvents the benefits of the type system since
the structure of a JSON is not known at compile time.

Another complicating factor is all the extra record metadata in SObject JSONs that allow them to
integrate with Salesforce. An example of this is the inclusion of the `__LOCAL*__` flags in records
which MobileSync needs to perform its sync operations. Care must be taken when manipulating these
flags, and low-level details like this should not be a concern of the UI and business layers.

To address these pain points, this template provides a simple framework for working with SObject
record JSONs in Kotlin, where the major design goals were aimed at keeping the app code as flexible
and extensible as Salesforce itself.

### The `SObject` Interface

```kotlin
interface SObject {
    fun JSONObject.applyObjProperties(): JSONObject
    val objectType: String
}
```

This interface defines a simple contract: any implementation of `SObject` must take a JSON and apply
its member properties to it. For the `ContactObject` it looks something like this (simplified for
illustrative purposes):

```kotlin
data class ContactObject(
    val firstName: String?,
    val lastName: String,
    val title: String?,
    val department: String?,
) : SObject {
    override val objectType: String = Constants.CONTACT

    val fullName = formatFullName(firstName = firstName, lastName = lastName)

    override fun JSONObject.applyObjProperties() = this.apply {
        putOpt(KEY_FIRST_NAME, firstName)
        putOpt(KEY_LAST_NAME, lastName)
        putOpt(KEY_TITLE, title)
        putOpt(KEY_DEPARTMENT, department)
        putOpt(Constants.NAME, fullName)
    }

    // ...
}
```

You can see that `ContactObject` implements `JSONObject.applyObjProperties()` by simply applying its
class properties to the JSON. This is used by the Repo for applying SObject properties to the JSON.
Here is a simple example to illustrate how this works:

```kotlin
/* Exception handling and DB transactions not shown */

class ContactsRepo : SObjectSyncableRepo<ContactObject> {
    override suspend fun locallyUpdate(id: String, so: ContactObject): SObjectRecord<ContactObject> {
        val retrievedElt = store.retrieveById(id)

        with(so) {
            retrievedElt.applyObjProperties()
        }

        val updatedElt = store.upsert(soupName, retrievedElt)
        // ...
    }

    // ...
}
```

The Repo pulls the JSON record from SmartStore, uses `ContactObject` implementation of
`applyObjProperties()` to mutate the record, and then it saves it back to SmartStore.

Notice how only the properties of the `ContactObject` data class are applied to the record JSON.
Importantly, _it leaves all other data in the record untouched._ This is key because it allows your
app to precisely manipulate exactly what properties of the SObject you want without losing any data.
You as the developer are in complete control of your runtime data model, and by implementing this
interface you exactly define what modeled properties apply to the JSON.

### The `SObjectDeserializer` Interface

What we have shown thus far is serializing data into the SObject records, but the app also needs to
deserialize the JSONs into those runtime data models. To facilitate that the framework also includes
the `SObjectDeserializer` interface:

```kotlin
interface SObjectDeserializer<T : SObject> {
    @Throws(CoerceException::class)
    fun coerceFromJsonOrThrow(json: JSONObject): SObjectRecord<T>
}
```

Implementations of this interface are how JSON is turned into runtime models, and it is used by the
Repos when giving the records back to the UI and Business layers of the app. An example of how the
you may implement this for the `ContactObject` could look like:

```kotlin
object ContactObjectDeserializer : SObjectDeserializer<ContactObject> {
    @Throws(CoerceException::class)
    override fun coerceFromJsonOrThrow(json: JSONObject): SObjectRecord<ContactObject> {
        // First check common SObject properties:
        SObjectDeserializerHelper.requireSoType(json, Constants.CONTACT)
        val id = SObjectDeserializerHelper.getIdOrThrow(json)
        val syncState = SObjectDeserializerHelper.getSyncState(json)

        // Now do SObject property validation specific to this SObject:
        val lastName = json.optString(KEY_LAST_NAME)
        if (lastName.isBlank) {
            throw InvalidPropertyValue(/*...*/)
        }

        // JSON passed all validation, now we can build the model instance:
        val model = ContactObject(
            firstName = json.optString(KEY_FIRST_NAME),
            lastName = lastName,
            title = json.optString(KEY_TITLE),
            department = json.optString(KEY_DEPARTMENT),
        )

        return SObjectRecord(id, syncState, model)
    }
}
```

The Salesforce standard Contact SObject has only one required field (the contact's last name), but
the flexibility of `SObjectDeserializer` means you can include whatever business logic you want that
fits your app's use-case.

Putting it all together, the Repo update method would look something like this:

```kotlin
/* Exception handling and DB transactions not shown */

class ContactsRepo : SObjectSyncableRepo<ContactObject> {
    private val deserializer = ContactObjectDeserializer

    override suspend fun locallyUpdate(id: String, so: ContactObject): SObjectRecord<ContactObject> {
        val retrievedElt = store.retrieveById(id)

        with(so) {
            retrievedElt.applyObjProperties()
        }

        val updatedElt = store.upsert(soupName, retrievedElt)
        return deserializer.coerceFromJsonOrThrow(updatedElt)
    }

    // ...
}
```

### SObject Framework Summary

All of this scaffolding and framework code is to create the bridge between data classes and JSON.
The data class models are immutable, following Jectpack Compose and Kotlin Flow best practices, and
the SObject implementation provides the way for the Repo to precisely apply only the data class
properties to a Soup entry.

UI and Business logic only work with immutable data classes, Jetpack Compose and Kotlin Flow are
happy with their built-in object equality semantics, and the Repos have a simple way to delegate
mutating JSON objects. Win, win, win!

## Flexible UI

The remainder of this README is dedicated to explaining the project structure for UI components and
why certain choices were made. This topic is not specific to Salesforce.

Jetpack Compose, Android 12L, and Jetpack Window Manager make up Android's solution to foldable
devies and other flexible UI situations. Native Android apps can now be run on Chromebooks and the
Windows Subsystem for Android, both of which allow for arbitrary resizing of app windows. Apps now
need to change their content and layout in response to window size changes, and developers need to
start thinking about apps behaving in these environments. Foldables further change the once-rigid
screen into a dynamic part of the user experience.

While hinge detection and layout around device features was not done in v1.0 of this template,
designing for these flexible UI situations was a core part of writing this template.

### UI Components

Android introduced Fragments as the way to create reusable, decoupled UI components that could be
dynamically placed in an Activity. Apps could choose their layout based on minimum device/window
size requirements and then execute Fragment transactions to add those UI components to the Activity.
Now that Jetpack Compose has arrived, however, the definition of a "UI component" is more
generalized and no longer tied to the concept of Fragments.

In this template, UI components are abstractly defined as **the smallest set of UI elements which
create a single logical piece of UI the user can interact with.** They are indivisible, decoupled
from any other UI component, and can be reused anywhere in the app.

There are two main UI components in this template: The Contacts List Component and the Contact
Details Component. Each represent exactly one thing a user can do within the app. The user can 1)
View a list of Contacts, and 2) View and edit details about a specific contact. These two tasks
cannot be divided any further, and prior to Jetpack Compose these two UI components would be
implemented with Fragments.

This template contains no Fragments; instead, only top-level Composables serve as the component
definitions. The two main UI components mentioned previously are implemented in
`ContactsListContentCore.kt` and `ContactDetailsContentCore.kt` simply as Composable functions.

By doing this, something interesting happens that may not be immediately obvious: we've defined an
`interface` for these UI components. The UI components' Composable function signatures define what
data each component needs to create the UI, and the component can be embedded anywhere so long as
the expected data are provided. Semantically, this makes each Composable component _behave_ like an
`interface` definition, and we get the benefits of interface segregation and encapsulation out of
the box.

There is no need for any Fragments, transactions, or Intents to add or remove UI components from the
UI. Just call the appropriate component's Composable function and give it the data it needs. Simple!

### The Interactions of Related UI Components

You will see that the `contacts.listcomponent` and `contacts.detailscomponent` packages exist as
_siblings_ to both each other and the `contacts.activity` package where the Contacts Activity and
View Model are defined. This is done for a very specific reason that has far reaching implications.

One of the most important things to remember when creating flexible UI is that _any_ component may
be on the screen at any time in combination with any other related **or unrelated** UI components.
For this reason, UI components should be designed to be completely independent from each other,
_even if they are logically related to other components._

The Contact Details component is completely isolated from the Contacts List, and vice-versa. The two
UI components are fundamentally related, but they are not _coupled_. Again, these component
definitions are like `interfaces`.  They should be able to exist on their own so long as their
contract is fulfilled.

### Activities As They Were Intended

> An activity is a single, focused thing that the user can do.
>
>   - https://developer.android.com/reference/android/app/Activity

This brings us finally to the subject of Activities. The Activity is still an integral part of
Android's runtime, but with Android View Models binding directly to Compose and no Fragment
transactions to deal with, an Activity takes on a different role within an app more closely akin to
their initial intention.

Activities are, semantically, the realization of an abstract task a user can carry out which relies
on sets of disparate UI components. The Contact Details component and the Contacts List component
are decoupled to each other _until_ an Activity is defined which introduces the coupling. The
Contacts Activiy and the corresponding Contacts Activity View Model are the realization of the task
of a user interacting with their contacts -- much like the Contacts tab in a typical Salesforce Org.

This is the paradigm shift. **All UI components are only related to each other through the
implementation of an Activity's View Model.** UI components themselves remain completely reusable
and decoupled, and it leaves it up to higher-level logic to combine them into meaningful tasks.

Implementation of `ContactsActivityViewModel` and the related `ContactsActivityContent.kt`
Composables was all done after designing the Contacts List and Contact Details UI components
individually. This template's implementation is complex, but this is only one interpretation of how
to implement the interactions between these two UI components. If you as the developer wanted to
change everything about how these UI components interacted, you could do so without changing the
components themselves.

### The Fate of Fragments

As a quick aside, it is worth pointing out that Fragments do still have their place in this pattern
for designing reusable components and flexible UI. Jetpack Navigation is still a very powerful way
to handle top-level navigation in an App. If relying on "single activity" navigation, Framents take
the place of Activities from the previous discussion, and all of the above still applies.
