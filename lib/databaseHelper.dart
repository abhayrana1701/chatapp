import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  // Initialize the database for a specific user
  Future<Database> initDatabase(String userId) async {
    _database = await _initUserDatabase(userId+"aaalahklaak");
    return _database!;
  }

  // Getter for database, ensure it's initialized
  Future<Database> get database async {
    if (_database == null) {
      throw Exception("Database not initialized. Call initDatabase(userId) first.");
    }
    return _database!;
  }

  // Initialize the user-specific database
  Future<Database> _initUserDatabase(String userId) async {
    String path = join(await getDatabasesPath(), '${userId}_chat_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE contacts(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT,
      username TEXT,
      name TEXT,
      profilePic BLOB,
      isLiveChatEnabled INTEGER DEFAULT 0,
      isLanguageTranslationEnabled INTEGER DEFAULT 0,
      translateTo TEXT DEFAULT 'English',
      translateFrom TEXT DEFAULT 'Auto Detect Language',
      translateToKey TEXT DEFAULT 'en',
      translateFromKey TEXT DEFAULT 'auto',
      about TEXT DEFAULT 'none'
    )
  ''');

    await db.execute('''
    CREATE TABLE user_data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      userId TEXT NOT NULL,
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      profilePic BLOB,
      onlyNotifiedFor TEXT DEFAULT '',
      isSmartPingEnabled TEXT DEFAULT 'no'
    )
''');
  }


  Future<void> updateNotifiedFor(String userId,String onlyNotifiedFor) async {
    final db = await database;
    await db.update(
      'user_data',
      {'onlyNotifiedFor': onlyNotifiedFor}, // the new value to set
      where: 'userId = ?', // filter condition
      whereArgs: [userId], // the userId to match
    );
  }

  Future<void> updateSmartPingEnabled(String userId, String isSmartPingEnabled) async {
    final db = await database;
    await db.update(
      'user_data',
      {'isSmartPingEnabled': isSmartPingEnabled}, // the new value to set
      where: 'userId = ?', // filter condition
      whereArgs: [userId], // the userId to match
    );
  }

  // Function to get onlyNotifiedFor and isSmartPingEnabled fields
  Future<Map<String, String?>> getUserNotificationSettings(String userId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'user_data',
      columns: ['onlyNotifiedFor', 'isSmartPingEnabled'],  // Select only the fields we need
      where: 'userId = ?',  // Filter condition
      whereArgs: [userId],  // The userId to match
    );

    if (result.isNotEmpty) {
      return {
        'onlyNotifiedFor': result[0]['onlyNotifiedFor'],
        'isSmartPingEnabled': result[0]['isSmartPingEnabled'],
      };
    } else {
      return {'onlyNotifiedFor': null, 'isSmartPingEnabled': null};  // Return null if no data found
    }
  }





  Future<Map<String, dynamic>?> getLanguageTranslationSettings(String userId) async {
    final db = await database;
    try {
      // Query the database to get the required fields for the given userId
      final List<Map<String, dynamic>> result = await db.query(
        'contacts',
        columns: [
          'isLanguageTranslationEnabled',
          'translateToKey',
          'translateFromKey',
        ],
        where: 'userId = ?',
        whereArgs: [userId],
      );

      // Check if the result contains any data
      if (result.isNotEmpty) {
        return result.first; // Return the first matching row
      } else {
        return null; // No data found for the given userId
      }
    } catch (e) {
      print('Error fetching language translation settings: $e');
      return null; // Return null on error
    }
  }



  Future<void> updateProfilePic(String userId, Uint8List profilePic) async {
    final db = await database;

    try {
      // Update the profilePic field for the given userId
      await db.update(
        'user_data',
        {'profilePic': profilePic},
        where: 'userId = ?',
        whereArgs: [userId],
      );

      print("Profile picture updated successfully in SQLite.");
    } catch (e) {
      print("Error updating profile picture: $e");
    }
  }

  Future<int> insertUser({
    required String username,
    required String userId,
    required String name,
    required String email,
    Uint8List? profilePic,
  }) async {
    final db = await database;

    final data = {
      'username': username,
      'userId': userId,
      'name': name,
      'email': email,
      'profilePic': profilePic,
    };

    await db.delete('user_data');
    return await db.insert('user_data', data);
  }

  // Fetch single user data by id (assuming only one user exists)
  Future<Map<String, dynamic>?> getUser() async {
    final db = await database;

    // Fetch the first user from the table (assuming only one)
    List<Map<String, dynamic>> result = await db.query('user_data', limit: 1);

    if (result.isNotEmpty) {
      return result.first; // Return the first (and only) record
    }
    return null; // Return null if no user found
  }

  Future<void> updateAbout(String userId, String about) async {
    final db = await database;
    await db.update(
      'contacts',
      {'about': about},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }



  /////////////////////////////////////////
  //Functions to handle contact related tasks
  Future<bool> isContactExists(String userId) async {
    final db = await database;
    var result = await db.query(
      'contacts',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty;
  }

  Future<void> insertContact(Map<String, dynamic> contact) async {
    final db = await database;
    await db.insert('contacts', contact);
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await database;
    return await db.query('contacts');
  }


  Future<void> markMessagesAsRead(String currentUserId, String userId2) async {
    final db = await database;

    // Update the isRead field to 1 for messages where userId != currentUserId
    await db.rawUpdate(
      "UPDATE chat_${currentUserId}_$userId2 SET isRead = 1 WHERE senderId != ? AND isRead = 0",
      [currentUserId],
    );
  }

  Future<List<Map<String, dynamic>>> getRecentChats(String currentUserId, String userId2) async {
    final db = await database;

    // Check if the table exists
    final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='chat_${currentUserId}_$userId2'"
    );

    // If the table does not exist, return an empty list
    if (tableExists.isEmpty) {
      return [];
    }

    // Fetch the last inserted chat using ROWID
    final result = await db.rawQuery(
        "SELECT *, (SELECT COUNT(*) FROM chat_${currentUserId}_$userId2 WHERE isRead = 0 AND senderId != '$currentUserId') AS unreadCount FROM chat_${currentUserId}_$userId2 WHERE ROWID = (SELECT MAX(ROWID) FROM chat_${currentUserId}_$userId2)"
    );

    // If there's no recent chat, return an empty list
    return result.isNotEmpty ? result : [];
  }




  ///////////////////////////////////


  ///////////////////////////////////
  //Functions to handle chats
  Future<void> _createChatTable(String userId1, String userId2) async {
    Database db = await database;
    String tableName = 'chat_${userId1}_${userId2}';
    await db.execute(
        '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      senderId INTEGER,
      messageId TEXT,
      content TEXT,
      timestamp TEXT,
      messageType TEXT,
      translatedToKey TEXT DEFAULT 'none',
      isRead INTEGER DEFAULT 1,        
      isDelivered INTEGER DEFAULT 0, 
      isReceived INTEGER DEFAULT 0
    )
    '''
    );
  }

  Future<void> updateMessageContent(
      String userId1,
      String userId2,
      String messageId,
      String newContent,
      String translatedToKey,
      ) async {
    Database db = await database;
    String tableName = 'chat_${userId1}_${userId2}';

    try {
      // Perform the update query with both fields
      int count = await db.update(
        tableName,
        {
          'content': newContent,       // New value for the `content` field
          'translatedToKey': translatedToKey // New value for the `translatedTo` field
        },
        where: 'messageId = ?',        // Condition for the update
        whereArgs: [messageId],        // Arguments to prevent SQL injection
      );

      if (count > 0) {
        print('Message updated successfully.');
      } else {
        print('Message not found with messageId: $messageId');
      }
    } catch (e) {
      print('Error updating message content: $e');
    }
  }


  Future<void> deleteTable(String userId1, String userId2) async {
    Database db = await database;
    String tableName = 'chat_${userId1}_${userId2}';
    try {
      // Execute the SQL command to delete all rows from the table
      await db.delete(tableName);
      print('All rows from table $tableName have been deleted.');
    } catch (e) {
      print('Error deleting rows from table $tableName: $e');
    }
  }




  Future<int> insertChat(String userId1, String userId2, Map<String, dynamic> chat) async {
    Database db = await database;
    await _createChatTable(userId1, userId2);
    String tableName = 'chat_${userId1}_$userId2';
    return await db.insert(
      tableName,
      chat,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }



  Future<void> updateFilePath({
    required String messageId,
    required String userId1,
    required String userId2,
    required String newFilePath,
  }) async {
    final db = await database; // Get the database instance
    String tableName = 'chat_${userId1}_$userId2';

    // Retrieve the current content for the specific messageId
    final List<Map<String, dynamic>> result = await db.query(
      tableName,
      columns: ['content'],
      where: 'messageId = ?',
      whereArgs: [messageId],
    );

    if (result.isNotEmpty) {
      // Parse the content JSON and update the file path
      Map<String, dynamic> contentJson = jsonDecode(result.first['content']);
      contentJson['path'] = newFilePath; // Update only the filePath field

      // Update the database with the modified content JSON
      await db.update(
        tableName,
        {'content': jsonEncode(contentJson)},
        where: 'messageId = ?',
        whereArgs: [messageId],
      );
      print("File path updated for message ID: $messageId in table $tableName");
    } else {
      print("Message ID not found: $messageId");
    }
  }



  Future<void> updateMessageDeliveryStatus({
    required String messageId,
    required int isDelivered,
    required userId1,
    required userId2
  }) async {
    String tableName = 'chat_${userId1}_$userId2';
    final db = await database;
    await db.update(
      tableName,
      {'isDelivered': isDelivered},
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }
  // Function to delete a message by messageId
  Future<int> deleteMessageById(String messageId,String userId1,String userId2) async {
    final db = await database;
    String tableName = 'chat_${userId1}_$userId2';
    // Use the 'DELETE FROM' SQL command
    return await db.delete(
      tableName, // Your table name
      where: 'messageId = ?', // WHERE clause
      whereArgs: [messageId], // Arguments for WHERE clause
    );
  }


  Future<void> updateMessageReceivedStatus({
    required String messageId,
    required userId1,
    required userId2
  }) async {
    String tableName = 'chat_${userId1}_$userId2';
    final db = await database;
    await db.update(
      tableName,
      {'isReceived': 1},
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }


  Future<List<Map<String, dynamic>>> loadChats(String userId1,String userId2) async {
    final db = await database; // Get the database instance
    String tableName = 'chat_${userId1}_$userId2';
    print("Table $tableName");
    // Query to get all chats ordered by the primary key id
    final List<Map<String, dynamic>> chatMessages = await db.query(
      tableName, // Replace with your actual table name
      orderBy: 'id ASC',
    );
    return chatMessages;
  }
  //////////////////////////////////////////////


  //Functions to get and update live chat status
  Future<int?> getLiveChatStatus(String userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'contacts',
      columns: ['isLiveChatEnabled'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.first['isLiveChatEnabled'] as int;  // Return the live chat status
  }

  Future<void> updateLiveChatStatus(String userId, int isLiveChatEnabled) async {
    Database db = await database;

    await db.update(
      'contacts',
      {'isLiveChatEnabled': isLiveChatEnabled},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }



  //Functions to get and update language translation status
  Future<int?> getLanguageTranslationStatus(String userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'contacts',
      columns: ['isLanguageTranslationEnabled'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.first['isLanguageTranslationEnabled'] as int;  // Return the live chat status
  }

  Future<String?> getTranslateToStatus(String userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'contacts',
      columns: ['translateTo'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.first['translateTo'] as String;  // Return the live chat status
  }

  Future<String?> getTranslateFromStatus(String userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'contacts',
      columns: ['translateFrom'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.first['translateFrom'] as String;  // Return the live chat status
  }

  Future<void> updateLanguageTranslationStatus(String userId, int isLanguageTranslationEnabled) async {
    Database db = await database;

    await db.update(
      'contacts',
      {'isLanguageTranslationEnabled': isLanguageTranslationEnabled},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateTranslateToStatus(String userId, String translateTo) async {
    Database db = await database;

    await db.update(
      'contacts',
      {'translateTo': translateTo},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateTranslateFromStatus(String userId, String translateFrom) async {
    Database db = await database;

    await db.update(
      'contacts',
      {'translateFrom': translateFrom},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<String?> getTranslateToKeyStatus(String userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'contacts',
      columns: ['translateToKey'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.first['translateToKey'] as String;  // Return the live chat status
  }

  Future<String?> getTranslateFromKeyStatus(String userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'contacts',
      columns: ['translateFromKey'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.first['translateFromKey'] as String;  // Return the live chat status
  }

  Future<void> updateTranslateToKeyStatus(String userId, String translateToKey) async {
    Database db = await database;

    await db.update(
      'contacts',
      {'translateToKey': translateToKey},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateTranslateFromKeyStatus(String userId, String translateFromKey) async {
    Database db = await database;

    await db.update(
      'contacts',
      {'translateFromKey': translateFromKey},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // Function to update the 'isReceived' status of a message based on its messageId
  Future<void> updateReceivedStatus({
    required String messageId,
    required String userId1,
    required String userId2,
  }) async {
    final db = await database; // Ensure the database is initialized
    String tableName = 'chat_${userId1}_$userId2';

    await db.update(
      tableName,
      {'isReceived': 1}, // Set isReceived to 1
      where: 'messageId = ?', // Update where messageId matches
      whereArgs: [messageId],
    );
    print("Received status updated for message ID: $messageId in table $tableName");
  }



}
