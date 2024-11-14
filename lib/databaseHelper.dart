import 'dart:convert';

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
    _database = await _initUserDatabase(userId);
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
      profilePic TEXT,
      isLiveChatEnabled INTEGER DEFAULT 0,
      isLanguageTranslationEnabled INTEGER DEFAULT 0,
      translateTo TEXT DEFAULT 'English',
      translateFrom TEXT DEFAULT 'Auto Detect Language',
      translateToKey TEXT DEFAULT 'en',
      translateFromKey TEXT DEFAULT 'auto',
      about TEXT DEFAULT 'none'
    )
  ''');
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

  Future<List<Map<String, dynamic>>> getRecentChats(String currentUserId,String userId2) async {
    final db = await database;
    return await db.query(
      'chat_${currentUserId}_$userId2',
      orderBy: 'timestamp DESC', // Assuming 'timestamp' stores the chat time
      limit: 1, // Get only the most recent chat
    );
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
      translatedTo TEXT DEFAULT 'none',
      isRead INTEGER DEFAULT 0,        
      isDelivered INTEGER DEFAULT 0, 
      isReceived INTEGER DEFAULT 0
    )
    '''
    );
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
