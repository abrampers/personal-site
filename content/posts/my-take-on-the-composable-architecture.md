+++
title = "My take on The Composable Architecture"
author = ["Abram Perdanaputra"]
date = 2020-10-25T10:08:00+07:00
draft = false
+++

<div class="ox-hugo-toc toc local">
<div></div>

- [Context: Typical iOS App Architecture](#context-typical-ios-app-architecture)
- [The claim](#the-claim)
- [Experiments](#experiments)
- [What I love](#what-i-love)
- [What I don't love](#what-i-don-t-love)
- [Where should I go next?](#where-should-i-go-next)
- [References](#references)

</div>
<!--endtoc-->

The Composable Architecture or TCA for short is a library to build application in a consistent and understandable manner, with composition, testing, and ergonomics in mind. This library is made by Point-Free to apply the concepts of functional programming in a practical way.


## Context: Typical iOS App Architecture {#context-typical-ios-app-architecture}

In the world of iOS development, there's a few 4 most commonly used patterns in architecting an iOS application. Most notably MVC, MVP, MVVM, and VIPER. The details of these architecture is beyond the scope of this article. All these architecture has their own advantages and drawbacks. For example, MVC is simple but misusing it will cause a Massive View Controller. VIPER provides a good testability but it'll generate much boilerplate code. At the end of the day, architectural decisions are based on the combination of use case, complexity, and many other variables. So there's no such thing as the silver bullet of iOS architecture.


## The claim {#the-claim}

As the new guy in the iOS architecture neighborhood, TCA claims to provide:

-   **Consistency**: degree of firmness, density, viscosity, or resistance to movement or separation of constituent particles
-   **Composition**: a product of mixing or combining various elements or ingredients
-   **Testing**
-   **Ergonomics**: a product of mixing or combining various elements or ingredients

In this blog, we'll test whether TCA fulfills what it claims to do or not.


## Experiments {#experiments}

We'll create a song reader app that have the capability to add songs to favorites and see all the favorites we have. All the code snippet in this blog is taken from my [Lagu Sion implementation](https://github.com/abrampers/lagu-sion-ios).


### Setting up {#setting-up}

To install this library, generate a new iOS application in your Xcode and add TCA to your Swift Package Dependency. More info, [head here](https://github.com/pointfreeco/swift-composable-architecture#installation).


### Building the app {#building-the-app}

In this blog, I'll build the app from the smallest component possible and work ourselves up and wire everything up.


#### Modeling song {#modeling-song}

Simple, we can make a struct that contains all the fields needed. In this case we need to generate the id and song

```swift

public struct Song: Equatable, Identifiable {
    public let id: UUID
    public let number: Int
    public let title: String
    public let verses: [Verse]
    public let reff: Verse?
    public let songBook: SongBook

    public init(id: UUID, number: Int, title: String, verses: [Verse], reff: Verse? = nil, songBook: SongBook) {
        self.id = id
        self.number = number
        self.title = title
        self.verses = verses
        self.reff = reff
        self.songBook = songBook
    }

    public var prefix: String { songBook.prefix }
    public var color: Color { songBook.color }
}

public struct SongViewState: Equatable, Identifiable {
    public var id: UUID {
        return song.id
    }

    public var song: Song
    public var isFavorite: Bool

    public init(song: Song, isFavorite: Bool) {
        self.song = song
        self.isFavorite = isFavorite
    }
}

extension SongViewState {
    var number: Int { song.number }
    var title: String { song.title }
    var verses: [Verse] { song.verses }
    var reff: Verse? { song.reff }
    var prefix: String { song.prefix }
    var color: Color { song.color }
}
```


#### Modeling action to be made on Song View {#modeling-action-to-be-made-on-song-view}

Simple, just use Swift’s enum to enumerate all the possible action.

```swift

public enum SongAction: Equatable {
    case heartTapped
    case removeFromFavorites
    case addToFavorites
}
```


#### Modeling what will happen when action appears {#modeling-what-will-happen-when-action-appears}

Here, we start to use TCA’s first feature: Reducer. TCA will receive all the action that the views will trigger and after that, the action will be processed through the reducer. In TCA, reducer is the place where logic happens. State mutations, logical operation, and action handling is happening in the reducer.

```swift

public let songReducer = Reducer<SongViewState, SongAction, SongEnvironment> { state, action, environment in
    switch action {
    case .heartTapped:
        if !state.isFavorite {
            return Effect(value: SongAction.addToFavorites)
        } else {
            return Effect(value: SongAction.removeFromFavorites)
        }

    case .addToFavorites, .removeFromFavorites:
        return .none
    }
}
```


#### Implement how the Song View will look like {#implement-how-the-song-view-will-look-like}

Simple, we create a view just like other SwiftUI views, but at the end, we’ll wire up the view with the state through a concept called `Store`

```swift

private struct TitleView: View {
    let title: String

    var body: some View {
        HStack {
            Spacer()
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .`default`))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

private struct VerseView: View {
    let verse: Verse

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            ForEach(0..<self.verse.contents.count) { (j) in
                Text(self.verse.contents[j])
            }
        }
    }
}

public struct SongView: View {
    private let store: Store<SongViewState, SongAction>
    private let enableFavoriteButton: Bool

    public init(store: Store<SongViewState, SongAction>, enableFavoriteButton: Bool) {
        self.store = store
        self.enableFavoriteButton = enableFavoriteButton
    }

    public var body: some View {
        WithViewStore(self.store) { viewStore in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .center, spacing: 10) {
                    Spacer()
                    TitleView(title: viewStore.title)
                    Spacer()
                    ForEach(0..<viewStore.verses.count) { i in
                        Text("\(i + 1)")
                            .font(.system(.headline))
                        VerseView(verse: viewStore.verses[i])
                        Unwrap(viewStore.reff) { reff in
                            Spacer()
                            VerseView(verse: reff)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .navigationBarTitle(Text("\(viewStore.prefix) no. \(viewStore.number)"))
            .navigationBarItems(
                trailing: Button(action: { viewStore.send(.heartTapped) }) {
                    Image(systemName: viewStore.isFavorite ? "heart.fill" : "heart")
                }
                .disabled(!self.enableFavoriteButton)
            )
        }
    }
}
```


#### Previews {#previews}

Since we haven’t wire up the view to any entry point, we can use SwiftUI previews to see how our view implementation is going.

```swift

internal struct SongView_Previews: PreviewProvider {
    static var previews: some View {
        SongView(
            store: Store(
                initialState: SongViewState(
                    song: Song(
                        id: UUID(),
                        number: 1,
                        title: "Di Hadapan Hadirat-Mu",
                        verses: [
                            Verse(contents: [
                                "Di hadapan hadirat-Mu",
                                "Kami umat-Mu menyembah",
                                "Mengakui Engkau Tuhan",
                                "Allah kekal, Maha kuasa"
                            ]),
                            Verse(contents: [
                                "Dari debu dan tanahlah",
                                "kita dijadikan Tuhan",
                                "Dan bila tersesat kita",
                                "Tuhan tak akan tinggalkan",
                            ]),
                            Verse(contents: [
                                "Kuasa serta kasih Allah",
                                "Memenuhi seg’nap dunia",
                                "Tetap teguhlah firman-Nya",
                                "Hingga penuh hadirat-Nya",
                            ]),
                            Verse(contents: [
                                "Di pintu Surga yang suci",
                                "menyanyi beribu lidah",
                                "Pada Tuhan kita puji",
                                "Sekarang dan selamanya",
                            ])
                        ], songBook: .laguSion
                    ),
                    isFavorite: false
                ),
                reducer: songReducer,
                environment: SongEnvironment()),
            enableFavoriteButton: true
        )
    }
}
```


#### Testing the implementation {#testing-the-implementation}

```swift

class SongTests: XCTestCase {
    func testHeartTapped_WithIsFavorite_False() {
        let store = TestStore(
            initialState: SongViewState(
                song: Song(id: UUID(), number: 0, title: "", verses: [], songBook: .laguSion),
                isFavorite: false
            ),
            reducer: songReducer,
            environment: SongEnvironment()
        )

        store.assert(
            .send(.heartTapped),
            .receive(.addToFavorites)
        )
    }

    func testHeartTapped_WithIsFavorite_True() {
        let store = TestStore(
            initialState: SongViewState(
                song: Song(id: UUID(), number: 0, title: "", verses: [], songBook: .laguSion),
                isFavorite: true
            ),
            reducer: songReducer,
            environment: SongEnvironment()
        )

        store.assert(
            .send(.heartTapped),
            .receive(.removeFromFavorites)
        )
    }
}
```

For now, let’s take a break from coding and look back what we have made here. First, we have modeled the state of the Song View and actions. Next the reducer and the view. TCA provides us with a framework to pass triggers from view to the reducer through `Store` . With store, developer can make SwiftUI previews easily. This checks the first claim that TCA is ergonomic.

Second, testing. `Store` concept also has it’s corresponding ergonomic component in testing named `TestStore` . This component enable us to intercept the actions triggered, sequence of actions, or even checks the state after every action sent or received. This checks the second claim that TCA is designed with testing in mind.

Cool, so far we have covered how TCA is ergonomic and designed with testing in mind. Let’s go to the next part of the implementation to prove the rest TCA claims.


#### Modeling Main List View {#modeling-main-list-view}

In the list view state, we store two lists. The list of songs, and favorite songs.

```swift

public struct MainState: Equatable {
    public var songs: [Song]
    public var favoriteSongs: [Song]
    public var selectedBook: BookSelection
    public var searchQuery: String
    public var selectedSortOption: SortOptions
    public var actionSheet: ActionSheetState<MainAction>?
    public var alert: AlertState<MainAction>?

    public init(
        songs: [Song] = [],
        favoriteSongs: [Song] = [],
        selectedBook: BookSelection = .all,
        searchQuery: String = "",
        selectedSortOptions: SortOptions = .number,
        actionSheet: ActionSheetState<MainAction>? = nil,
        alert: AlertState<MainAction>? = nil
    ) {
        self.songs = songs
        self.favoriteSongs = favoriteSongs
        self.selectedBook = selectedBook
        self.searchQuery = searchQuery
        self.selectedSortOption = selectedSortOptions
        self.actionSheet = actionSheet
        self.alert = alert
    }
}

extension MainState {
    var currentSongs: [SongViewState] {
        get {
            var result: [Song] = []
            switch selectedBook {
            case .all:
                result = songs
            case .songBook(let songBook):
                result = songs(for: songBook)
            }

            return result.map { song -> SongViewState in
                SongViewState(song: song, isFavorite: favoriteSongs.contains(song))
            }
        }
        set {
        }
    }

    func songs(for songBook: SongBook) -> [Song] {
        return songs.filter { song in
            song.songBook == songBook
        }
    }
}
```


#### Modeling the Main List View Actions {#modeling-the-main-list-view-actions}

Here, we’re going to use our previously made `songReducer` for each song we have in the main list.

```swift

public enum MainAction: Equatable {
    case actionSheetDismissed
    case alertDismissed
    case appear
    case error(LaguSionError)
    case getSongs
    case setSongs([Song])
    case saveSearchQuery(String)
    case searchQueryChanged(String)
    case song(index: Int, action: SongAction)
    case songBookPicked(BookSelection)
    case sortOptionChanged(SortOptions)
    case sortOptionTapped
    case updateFavoriteSongs(newFavorites: [Song])

    case noOp
}

public let mainReducer: Reducer<MainState, MainAction, MainEnvironment> = .combine(
    songReducer.forEach(
        state: \MainState.currentSongs,
        action: /MainAction.song(index:action:),
        environment: { _ in SongEnvironment() }
    ),
    // ...
)
```

Let’s take a break and see what we did. First, we model the `MainState` just as we did on `SongViewState` . After that, we create the model of `MainAction` and `mainReducer` . This shows that building component in TCA is consistent. Every layer of the implementation follows the same consistent pattern. This checks the consistency claim.

Next, TCA also gave us the tools we need to reuse and compose the `songReducer` in the `mainReducer`. As we know, the main state, composes song state directly or indirectly. If this happens, we can always compose any state with many other smaller states and we can still have the visibility of anything that happens in the child component. This checks the composability claim.

Last experiment I’d like to show is to fast forward on how we’re going to wire multiple sibling states to the root state.

Assume we have implemented the `Settings` and `Favorites` section.


#### Model App State {#model-app-state}

To wire up all the sibling states to single state, we have to define how are the `AppState` behave when there’s a change in `AppState` or if there’s any changes in the child states.

```swift

struct AppState: Equatable {
    var songs: [Song] = []
    var favoriteSongs: [Song] = []
    var selectedBook: BookSelection = .all
    var selectedSortOptions: SortOptions = .number
    var searchQuery: String = ""
    var mainActionSheet: ActionSheetState<MainAction>? = nil
    var mainAlert: AlertState<MainAction>? = nil
    var isAvailableOffline: Bool = false
    var fontSelection: FontSelection = .normal
    var contentSizeSelection: ContentSizeSelection = .normal
}

extension AppState {
    var main: MainState {
        get {
            MainState(
                songs: self.songs,
                favoriteSongs: self.favoriteSongs,
                selectedBook: self.selectedBook,
                searchQuery: self.searchQuery,
                selectedSortOptions: self.selectedSortOptions,
                actionSheet: self.mainActionSheet,
                alert: self.mainAlert
            )
        }
        set {
            self.songs = newValue.songs
            self.favoriteSongs = newValue.favoriteSongs
            self.selectedBook = newValue.selectedBook
            self.searchQuery = newValue.searchQuery
            self.selectedSortOptions = newValue.selectedSortOption
            self.mainActionSheet = newValue.actionSheet
            self.mainAlert = newValue.alert
        }
    }

    var favorites: FavoritesState {
        get {
            FavoritesState(songs: self.songs, favoriteSongs: self.favoriteSongs)
        }
        set {
            self.songs = newValue.songs
            self.favoriteSongs = newValue.favoriteSongs
        }
    }

    var settings: SettingsState {
        get {
            SettingsState(
                isAvailableOffline: self.isAvailableOffline,
                fontSelection: self.fontSelection,
                contentSizeSelection: self.contentSizeSelection
            )
        }
        set {
            self.isAvailableOffline = newValue.isAvailableOffline
            self.fontSelection = newValue.fontSelection
            self.contentSizeSelection = newValue.contentSizeSelection
        }
    }
}
```


#### Model Action and Reducer {#model-action-and-reducer}

```swift
enum AppAction {
    case main(MainAction)
    case favorites(FavoritesAction)
    case settings(SettingsAction)
}

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = .combine(
    mainReducer.pullback(
        state: \AppState.main,
        action: /AppAction.main,
        environment: { env in
            MainEnvironment(
                mainQueue: env.mainQueue,
                laguSionDataSource: env.laguSionDataSource
            )
        }
    ),
    favoritesReducer.pullback(
        state: \AppState.favorites,
        action: /AppAction.favorites,
        environment: { _ in FavoritesEnvironment() }
    ),
    settingsReducer.pullback(
        state: \AppState.settings,
        action: /AppAction.settings,
        environment: { _ in SettingsEnvironment() }
    )
)
```

Let’s stop and review again. In this section, we made the state, actions, and reducer. But if we look closely, `appReducer` is doing nothing but composing all the child reducers and passing its respective states and actions using `pullback`. This ultimately checks again the composability claim of TCA.


## What I love {#what-i-love}

As we can see from the experiment, TCA delivers what it promised. Consistency, Composability, Testing, and Ergonomic. Personally, my favorite thing in TCA is how we can build mini components and wire it up to the chain until it has reaches the root/single source of truth. This ensures data consistency throughout screen and states.


## What I don't love {#what-i-don-t-love}

Right now, there's no valid proof that this architecture is used in a huge app with high complexity. So we still have no idea on the extent of this architecture.


## Where should I go next? {#where-should-i-go-next}

If you're interested in how this library is designed, go to [Composable Architecture series](https://www.pointfree.co/collections/composable-architecture). If you're into functional programming, especially in Swift, check out [Point-Free's site](https://www.pointfree.co). They cover a lot of interesting ideas of functional programming specifically in Swift. If need more example of a working app using TCA, visit [TCA's GitHub examples](https://github.com/pointfreeco/swift-composable-architecture#examples).


## References {#references}

-   <https://github.com/pointfreeco/swift-composable-architecture>
