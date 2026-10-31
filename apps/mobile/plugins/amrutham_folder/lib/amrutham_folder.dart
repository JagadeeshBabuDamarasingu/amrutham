/// The native side only: the app talks to it over the `app.amrutham/folder`
/// method channel (see `lib/backup/backup_folder.dart` in the app). It is a
/// plugin so it is registered in every Flutter engine, including the one a
/// background backup task runs in; code in MainActivity would not be.
library;
