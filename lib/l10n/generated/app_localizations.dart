import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'NARA'**
  String get appName;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonErrorGeneric;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get commonTomorrow;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'NARA AI'**
  String get navChat;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get navHabits;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @ob1Title.
  ///
  /// In en, this message translates to:
  /// **'Meet NARA'**
  String get ob1Title;

  /// No description provided for @ob1Body.
  ///
  /// In en, this message translates to:
  /// **'Your personal smart companion that lives on your phone — helping you plan, focus, and grow every single day.'**
  String get ob1Body;

  /// No description provided for @ob2Title.
  ///
  /// In en, this message translates to:
  /// **'One app for your day'**
  String get ob2Title;

  /// No description provided for @ob2Body.
  ///
  /// In en, this message translates to:
  /// **'Capture tasks, save notes, and build habits in one elegant place. Everything stays in sync and works offline.'**
  String get ob2Body;

  /// No description provided for @ob3Title.
  ///
  /// In en, this message translates to:
  /// **'An assistant that acts'**
  String get ob3Title;

  /// No description provided for @ob3Body.
  ///
  /// In en, this message translates to:
  /// **'Chat naturally — \"remind me to stretch at 5\" — and NARA turns it into real tasks. Hybrid AI: instant on-device, smarter with cloud.'**
  String get ob3Body;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue with your companion.'**
  String get loginSubtitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few seconds to set up your NARA.'**
  String get registerSubtitle;

  /// No description provided for @authNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authNameLabel;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authHasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHasAccount;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authLocalBanner.
  ///
  /// In en, this message translates to:
  /// **'Local mode — data is stored only on this device. Connect Firebase for cloud sync.'**
  String get authLocalBanner;

  /// No description provided for @authLocalRegister.
  ///
  /// In en, this message translates to:
  /// **'Start with a profile'**
  String get authLocalRegister;

  /// No description provided for @authLocalRegisterHint.
  ///
  /// In en, this message translates to:
  /// **'No account needed in local mode. Add your name to personalize NARA.'**
  String get authLocalRegisterHint;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get authErrorNameEmpty;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Still up?'**
  String get greetingNight;

  /// No description provided for @dashTasksToday.
  ///
  /// In en, this message translates to:
  /// **'Tasks today'**
  String get dashTasksToday;

  /// No description provided for @dashHabitsToday.
  ///
  /// In en, this message translates to:
  /// **'Habits done'**
  String get dashHabitsToday;

  /// No description provided for @dashBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get dashBestStreak;

  /// No description provided for @dashNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get dashNotes;

  /// No description provided for @quickAddTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get quickAddTask;

  /// No description provided for @quickAddNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get quickAddNote;

  /// No description provided for @quickCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check in habit'**
  String get quickCheckIn;

  /// No description provided for @suggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'NARA suggests'**
  String get suggestionTitle;

  /// No description provided for @dashTodayTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tasks'**
  String get dashTodayTasks;

  /// No description provided for @dashEmptyTasks.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled. Add a task or ask NARA AI.'**
  String get dashEmptyTasks;

  /// No description provided for @dashSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get dashSeeAll;

  /// No description provided for @dashHabitsSection.
  ///
  /// In en, this message translates to:
  /// **'Habit check-in'**
  String get dashHabitsSection;

  /// No description provided for @dashAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done for today. Enjoy your day!'**
  String get dashAllDone;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'NARA AI'**
  String get chatTitle;

  /// No description provided for @chatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal assistant'**
  String get chatSubtitle;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Ask or command anything…'**
  String get chatHint;

  /// No description provided for @chatOfflineBadge.
  ///
  /// In en, this message translates to:
  /// **'On-device'**
  String get chatOfflineBadge;

  /// No description provided for @chatCloudBadge.
  ///
  /// In en, this message translates to:
  /// **'Cloud AI'**
  String get chatCloudBadge;

  /// No description provided for @chatThinking.
  ///
  /// In en, this message translates to:
  /// **'NARA is thinking…'**
  String get chatThinking;

  /// No description provided for @chatClear.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get chatClear;

  /// No description provided for @chatCleared.
  ///
  /// In en, this message translates to:
  /// **'Chat cleared.'**
  String get chatCleared;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Say hello to NARA'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Ask questions, create tasks by chatting, or just talk. Try one of these:'**
  String get chatEmptyBody;

  /// No description provided for @chatSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'What can you do?'**
  String get chatSuggestion1;

  /// No description provided for @chatSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'Create task \"buy groceries\" tomorrow'**
  String get chatSuggestion2;

  /// No description provided for @chatSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'How are my habits doing?'**
  String get chatSuggestion3;

  /// No description provided for @chatSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'I need some motivation'**
  String get chatSuggestion4;

  /// No description provided for @chatKeyBanner.
  ///
  /// In en, this message translates to:
  /// **'Connect a Gemini API key to unlock Cloud AI.'**
  String get chatKeyBanner;

  /// No description provided for @chatKeyAction.
  ///
  /// In en, this message translates to:
  /// **'Add key'**
  String get chatKeyAction;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @taskFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get taskFilterAll;

  /// No description provided for @taskFilterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get taskFilterToday;

  /// No description provided for @taskFilterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get taskFilterUpcoming;

  /// No description provided for @taskFilterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskFilterDone;

  /// No description provided for @taskTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get taskTitleLabel;

  /// No description provided for @taskNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get taskNoteLabel;

  /// No description provided for @taskPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskPriorityLabel;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @taskDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get taskDueLabel;

  /// No description provided for @taskNoDue.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get taskNoDue;

  /// No description provided for @taskCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get taskCategoryLabel;

  /// No description provided for @catGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get catGeneral;

  /// No description provided for @catWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get catWork;

  /// No description provided for @catStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get catStudy;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get catPersonal;

  /// No description provided for @taskAdded.
  ///
  /// In en, this message translates to:
  /// **'Task added'**
  String get taskAdded;

  /// No description provided for @taskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Task updated'**
  String get taskUpdated;

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeleted;

  /// No description provided for @taskEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'A clear day starts here'**
  String get taskEmptyTitle;

  /// No description provided for @taskEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first task, or ask NARA AI to do it for you.'**
  String get taskEmptyBody;

  /// No description provided for @taskOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get taskOverdue;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @notesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes…'**
  String get notesSearchHint;

  /// No description provided for @noteTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteTitleLabel;

  /// No description provided for @noteBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Start writing…'**
  String get noteBodyLabel;

  /// No description provided for @noteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteAdded;

  /// No description provided for @noteUpdated.
  ///
  /// In en, this message translates to:
  /// **'Note updated'**
  String get noteUpdated;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeleted;

  /// No description provided for @noteEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your mind, saved'**
  String get noteEmptyTitle;

  /// No description provided for @noteEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Capture ideas, plans, and thoughts before they slip away.'**
  String get noteEmptyBody;

  /// No description provided for @noteUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled note'**
  String get noteUntitled;

  /// No description provided for @notePinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get notePinned;

  /// No description provided for @habitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habitsTitle;

  /// No description provided for @habitNew.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get habitNew;

  /// No description provided for @habitNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Habit name'**
  String get habitNameLabel;

  /// No description provided for @habitEmojiLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get habitEmojiLabel;

  /// No description provided for @habitTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target per week'**
  String get habitTargetLabel;

  /// No description provided for @habitTimesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{n}× / week'**
  String habitTimesPerWeek(int n);

  /// No description provided for @habitCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get habitCheckIn;

  /// No description provided for @habitCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'{name} checked in — keep the streak!'**
  String habitCheckedIn(String name);

  /// No description provided for @habitStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{n}-day streak'**
  String habitStreakDays(int n);

  /// No description provided for @habitStreakOne.
  ///
  /// In en, this message translates to:
  /// **'1-day streak'**
  String get habitStreakOne;

  /// No description provided for @habitNoStreak.
  ///
  /// In en, this message translates to:
  /// **'Start a streak today'**
  String get habitNoStreak;

  /// No description provided for @habitEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Small steps, big change'**
  String get habitEmptyTitle;

  /// No description provided for @habitEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a habit like \"Read 10 pages\" and check in daily.'**
  String get habitEmptyBody;

  /// No description provided for @habitDeleted.
  ///
  /// In en, this message translates to:
  /// **'Habit deleted'**
  String get habitDeleted;

  /// No description provided for @habitDoneToday.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get habitDoneToday;

  /// No description provided for @weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get weeklyProgress;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileNameLabel;

  /// No description provided for @profileEmojiLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get profileEmojiLabel;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileSaved;

  /// No description provided for @statTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks done'**
  String get statTasks;

  /// No description provided for @statNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get statNotes;

  /// No description provided for @statHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get statHabits;

  /// No description provided for @settingsSection.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSection;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @langSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get langSystem;

  /// No description provided for @langIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get langIndonesian;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @settingsReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingsReminder;

  /// No description provided for @settingsReminderSub.
  ///
  /// In en, this message translates to:
  /// **'NARA checks in on you once a day'**
  String get settingsReminderSub;

  /// No description provided for @reminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTimeLabel;

  /// No description provided for @reminderSaved.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder set for {time}'**
  String reminderSaved(String time);

  /// No description provided for @reminderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder turned off'**
  String get reminderDisabled;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission was denied. Enable it from system settings.'**
  String get notificationPermissionDenied;

  /// No description provided for @settingsAiKey.
  ///
  /// In en, this message translates to:
  /// **'Cloud AI key'**
  String get settingsAiKey;

  /// No description provided for @settingsAiKeySub.
  ///
  /// In en, this message translates to:
  /// **'Custom AI endpoint, key & model'**
  String get settingsAiKeySub;

  /// No description provided for @aiKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Cloud AI'**
  String get aiKeyTitle;

  /// No description provided for @aiKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Paste your API key — Gemini or any OpenAI-compatible provider. Optionally set a custom Base URL and model. Everything stays on this device.'**
  String get aiKeyBody;

  /// No description provided for @aiKeyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get aiKeyFieldLabel;

  /// No description provided for @aiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Cloud AI connected. NARA is now smarter.'**
  String get aiKeySaved;

  /// No description provided for @aiKeyRemoved.
  ///
  /// In en, this message translates to:
  /// **'Cloud AI disconnected.'**
  String get aiKeyRemoved;

  /// No description provided for @aiKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'That key was rejected. Please double-check it.'**
  String get aiKeyInvalid;

  /// No description provided for @aiApiStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'API format'**
  String get aiApiStyleLabel;

  /// No description provided for @aiBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get aiBaseUrlLabel;

  /// No description provided for @aiBaseUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'That Base URL doesn\'t look right — use a full http(s):// address and a matching model.'**
  String get aiBaseUrlInvalid;

  /// No description provided for @aiModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get aiModelLabel;

  /// No description provided for @authGoogleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled or blocked by Google. Try again and pick your account — if it keeps happening, remove and re-add your Google account on this phone.'**
  String get authGoogleCancelled;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About NARA'**
  String get settingsAbout;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'NARA is your personal smart companion — tasks, notes, habits, and an AI assistant in one elegant app. Built with Flutter & Firebase.'**
  String get aboutBody;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {v}'**
  String aboutVersion(String v);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in anytime. Local preferences stay on this device.'**
  String get signOutConfirmBody;

  /// No description provided for @deleteData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteData;

  /// No description provided for @deleteDataConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteDataConfirmTitle;

  /// No description provided for @deleteDataConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your tasks, notes, habits, and chat history. This cannot be undone.'**
  String get deleteDataConfirmBody;

  /// No description provided for @deleteDataDone.
  ///
  /// In en, this message translates to:
  /// **'All data deleted.'**
  String get deleteDataDone;

  /// No description provided for @badgeLocalMode.
  ///
  /// In en, this message translates to:
  /// **'Local mode'**
  String get badgeLocalMode;

  /// No description provided for @badgeCloudMode.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get badgeCloudMode;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your smart companion'**
  String get splashTagline;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Changes will sync when you reconnect.'**
  String get errorOffline;

  /// No description provided for @timePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick reminder time'**
  String get timePickerTitle;

  /// No description provided for @datePickerToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get datePickerToday;

  /// No description provided for @datePickerTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get datePickerTomorrow;

  /// No description provided for @datePickerNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get datePickerNoDate;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
