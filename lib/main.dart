import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(CaloriesCalculatorApp());
}

class CaloriesCalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calories Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class DBHelper {
  Future<Database> database() async {
    final Directory dbDirectory = await getApplicationDocumentsDirectory();
    final String dbPath = join(dbDirectory.path, 'calories.db');

    return openDatabase(dbPath, version: 5, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE Food(
          id INTEGER PRIMARY KEY,
          name TEXT,
          calories INTEGER
        )
      ''');

      final foodItems = [
        {'name': 'Apple', 'calories': 95},
        {'name': 'Banana', 'calories': 105},
        {'name': 'Orange', 'calories': 62},
        {'name': 'Chicken breast (cooked)', 'calories': 165},
        {'name': 'Salmon (cooked)', 'calories': 233},
        {'name': 'White rice (cooked)', 'calories': 205},
        {'name': 'Whole wheat bread', 'calories': 69},
        {'name': 'Spinach (cooked)', 'calories': 41},
        {'name': 'Eggs (large, boiled)', 'calories': 78},
        {'name': 'Almonds', 'calories': 164},
        {'name': 'Greek yogurt', 'calories': 100},
        {'name': 'Broccoli (cooked)', 'calories': 55},
        {'name': 'Carrots (raw)', 'calories': 52},
        {'name': 'Oatmeal (cooked)', 'calories': 159},
        {'name': 'Avocado', 'calories': 234},
        {'name': 'Sweet potato (cooked)', 'calories': 180},
        {'name': 'Ground beef (lean, cooked)', 'calories': 250},
        {'name': 'Milk (2%)', 'calories': 122},
        {'name': 'Quinoa (cooked)', 'calories': 222},
        {'name': 'Cottage cheese', 'calories': 220},
      ];

      for (var foodItem in foodItems) {
        await db.insert('Food', foodItem);
      }
    }, onUpgrade: _onUpgrade);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS Food');
    await db.execute('DROP TABLE IF EXISTS MealPlan');

    await _createDatabase(db, newVersion);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Food(
        id INTEGER PRIMARY KEY,
        name TEXT,
        calories INTEGER
      )
    ''');
    final foodItems = [
      {'name': 'Apple', 'calories': 95},
      {'name': 'Banana', 'calories': 105},
      {'name': 'Orange', 'calories': 62},
      {'name': 'Chicken breast (cooked)', 'calories': 165},
      {'name': 'Salmon (cooked)', 'calories': 233},
      {'name': 'White rice (cooked)', 'calories': 205},
      {'name': 'Whole wheat bread', 'calories': 69},
      {'name': 'Spinach (cooked)', 'calories': 41},
      {'name': 'Eggs (large, boiled)', 'calories': 78},
      {'name': 'Almonds', 'calories': 164},
      {'name': 'Greek yogurt', 'calories': 100},
      {'name': 'Broccoli (cooked)', 'calories': 55},
      {'name': 'Carrots (raw)', 'calories': 52},
      {'name': 'Oatmeal (cooked)', 'calories': 159},
      {'name': 'Avocado', 'calories': 234},
      {'name': 'Sweet potato (cooked)', 'calories': 180},
      {'name': 'Ground beef (lean, cooked)', 'calories': 250},
      {'name': 'Milk (2%)', 'calories': 122},
      {'name': 'Quinoa (cooked)', 'calories': 222},
      {'name': 'Cottage cheese', 'calories': 220},
    ];

    for (var foodItem in foodItems) {
      await db.insert('Food', foodItem);
    }

    await db.execute('''
      CREATE TABLE MealPlan(
        id INTEGER PRIMARY KEY,
        foodId INTEGER,
        date TEXT,
        targetCalories INTEGER
      )
    ''');
  }
}

class FoodItem {
  final int id;
  final String name;
  final int calories;

  FoodItem({required this.id, required this.name, required this.calories});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
    };
  }
}

class DatabaseService {
  final DBHelper dbHelper = DBHelper();

  Future<void> saveMealPlan(DateTime selectedDate, FoodItem selectedFood, int targetCalories) async {
    final db = await dbHelper.database();

    await db.insert(
      'MealPlan',
      {
        'foodId': selectedFood.id,
        'date': selectedDate.toIso8601String(),
        'targetCalories': targetCalories,
      },
    );
  }
  Future<List<Map<String, dynamic>>> getFoodsForMealPlan(int mealPlanId) async {
    final db = await dbHelper.database();

    final List<Map<String, dynamic>> mealPlan = await db.query(
      'MealPlan',
      where: 'id = ?',
      whereArgs: [mealPlanId],
    );

    if (mealPlan.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> mealPlanFoods = await db.query(
      'MealPlanFood',
      where: 'mealPlanId = ?',
      whereArgs: [mealPlanId],
    );

    final List<Map<String, dynamic>> selectedFoods = [];

    for (var mealPlanFood in mealPlanFoods) {
      final int foodId = mealPlanFood['foodId'];
      final List<Map<String, dynamic>> food = await db.query(
        'Food',
        where: 'id = ?',
        whereArgs: [foodId],
      );

      if (food.isNotEmpty) {
        selectedFoods.add(food[0]);
      }
    }

    return selectedFoods;
  }



  Future<List<Map<String, dynamic>>> queryMealPlan(DateTime date) async {
    final db = await dbHelper.database();
    final List<Map<String, dynamic>> mealPlan = await db.query(
      'MealPlan',
      where: 'date = ?',
      whereArgs: [date.toIso8601String()],
    );

    return mealPlan;
  }

  Future<void> addMealPlan(DateTime selectedDate, FoodItem selectedFood, int targetCalories) async {
    final db = await dbHelper.database();

    await db.insert(
      'MealPlan',
      {
        'foodId': selectedFood.id,
        'date': selectedDate.toIso8601String(),
        'targetCalories': targetCalories,
      },
    );
  }

  Future<void> deleteMealPlan(int mealPlanId) async {
    final db = await dbHelper.database();

    await db.delete(
      'MealPlan',
      where: 'id = ?',
      whereArgs: [mealPlanId],
    );
  }

  Future<void> updateMealPlan(int mealPlanId, DateTime selectedDate, List<FoodItem> selectedFoods, int targetCalories) async {
    final db = await dbHelper.database();


    await db.update(
      'MealPlan',
      {
        'date': selectedDate.toIso8601String(),
        'targetCalories': targetCalories,
      },
      where: 'id = ?',
      whereArgs: [mealPlanId],
    );

    await db.delete(
      'MealPlanFood',
      where: 'mealPlanId = ?',
      whereArgs: [mealPlanId],
    );

    for (var food in selectedFoods) {
      await db.insert(
        'MealPlanFood',
        {
          'mealPlanId': mealPlanId,
          'foodId': food.id,
        },
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAllMealPlansWithFoods() async {
    final db = await dbHelper.database();
    final List<Map<String, dynamic>> mealPlans = await db.query('MealPlan');

    List<Map<String, dynamic>> mealPlansWithFoods = [];

    for (var mealPlan in mealPlans) {
      final List<Map<String, dynamic>> foods = await getFoodsForMealPlan(mealPlan['id']);
      final List<Map<String, dynamic>> formattedFoods = foods.map((food) {
        return {
          'name': food['name'],
          'calories': food['calories'],
        };
      }).toList();

      final Map<String, dynamic> mealPlanWithFoods = {
        'id': mealPlan['id'],
        'date': mealPlan['date'],
        'targetCalories': mealPlan['targetCalories'],
        'foods': formattedFoods,
      };

      mealPlansWithFoods.add(mealPlanWithFoods);
    }

    return mealPlansWithFoods;
  }


}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? selectedDate;
  int? selectedCalories;

  final DatabaseService databaseService = DatabaseService();
  List<FoodItem> foodItemsList = [];
  List<FoodItem> selectedFoods = [];

  @override
  void initState() {
    super.initState();
    databaseService.dbHelper.database();
    retrieveFoodItems();
  }

  Future<void> retrieveFoodItems() async {
    final db = await databaseService.dbHelper.database();
    final List<Map<String, dynamic>> foodItems = await db.query('Food');
    setState(() {
      foodItemsList = foodItems.map((foodMap) {
        return FoodItem(
          id: foodMap['id'],
          name: foodMap['name'],
          calories: foodMap['calories'],
        );
      }).toList();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calories Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: foodItemsList.length,
                      itemBuilder: (context, index) {
                        final foodItem = foodItemsList[index];
                        final bool isSelected = selectedFoods.contains(foodItem);

                        return CheckboxListTile(
                          title: Text(foodItem.name),
                          value: isSelected,
                          onChanged: (newValue) {
                            setState(() {
                              if (newValue != null && newValue) {
                                selectedFoods.add(foodItem);
                              } else {
                                selectedFoods.remove(foodItem);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Select Target Calories',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem<int>(
                  value: 1500,
                  child: Text('1500 Calories'),
                ),
                DropdownMenuItem<int>(
                  value: 2000,
                  child: Text('2000 Calories'),
                ),

              ],
              onChanged: (value) {
                setState(() {
                  selectedCalories = value;
                });
              },
            ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2021),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: Text(
                selectedDate != null
                    ? 'Selected Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                    : 'Select Date',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate != null && selectedFoods.isNotEmpty && selectedCalories != null) {
                  for (var food in selectedFoods) {
                    await databaseService.addMealPlan(selectedDate!, food, selectedCalories!);
                  }
                }
              },
              child: const Text('Add to Meal Plan'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MealPlansPage()),
                );
              },
              child: const Text('View All Meal Plans'),
            ),
          ],
        ),
      ),
    );
  }
}

class MealPlansPage extends StatefulWidget {
  @override
  _MealPlansPageState createState() => _MealPlansPageState();
}

class _MealPlansPageState extends State<MealPlansPage> {
  final DatabaseService databaseService = DatabaseService();
  List<Map<String, dynamic>> mealPlans = [];

  @override
  void initState() {
    super.initState();
    fetchMealPlans();
  }

  Future<void> fetchMealPlans() async {
    final List<Map<String, dynamic>> plans = await databaseService.getAllMealPlansWithFoods();
    setState(() {
      mealPlans = plans;
    });
  }

  Future<void> _deleteMealPlan(int mealPlanId) async {
    await databaseService.deleteMealPlan(mealPlanId);
    fetchMealPlans();
  }

  Future<void> _queryMealPlanForDate(DateTime selectedDate) async {
    final List<Map<String, dynamic>> plans = await databaseService.queryMealPlan(selectedDate);
    setState(() {
      mealPlans = plans;
    });
  }

  Future<void> _showDateSelector(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2021),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      await _queryMealPlanForDate(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Meal Plans'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () => _showDateSelector(context),
            child: Text('Query Meal Plan for Date'),
          ),
          Expanded(
            child: mealPlans.isNotEmpty
                ? ListView.builder(
              itemCount: mealPlans.length,
              itemBuilder: (context, index) {
                final plan = mealPlans[index];
                return ListTile(
                  title: Text('Meal Plan ID: ${plan['id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${plan['date']}'),
                      Text('Calories: ${plan['targetCalories']}'),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: databaseService.getFoodsForMealPlan(plan['id']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error fetching foods');
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Text('No Foods Available');
                          } else {
                            final foods = snapshot.data!;
                            final foodNames = foods.map((food) => food['name']).join(', ');
                            return Text('Foods: $foodNames');
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditMealPlanPage(mealPlan: plan),
                      ),
                    );
                  },
                );
              },
            )
                : Center(
              child: Text('No Meal Plans Available'),
            ),
          ),
        ],
      ),
    );
  }
}

class EditMealPlanPage extends StatefulWidget {
  final Map<String, dynamic> mealPlan;

  const EditMealPlanPage({Key? key, required this.mealPlan}) : super(key: key);

  @override
  _EditMealPlanPageState createState() => _EditMealPlanPageState();
}

class _EditMealPlanPageState extends State<EditMealPlanPage> {
  late DateTime selectedDate;
  late int selectedCalories;
  List<FoodItem> selectedFoods = [];
  List<FoodItem> allFoods = [];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.parse(widget.mealPlan['date']);
    selectedCalories = widget.mealPlan['targetCalories'];
    fetchSelectedFoods(widget.mealPlan['id']);
    retrieveAllFoods(widget.mealPlan['id']);
  }

  Future<void> fetchSelectedFoods(int mealPlanId) async {
    final List<Map<String, dynamic>> foods = await DatabaseService().getFoodsForMealPlan(mealPlanId);
    setState(() {
      selectedFoods = foods.map((foodMap) {
        return FoodItem(
          id: foodMap['id'],
          name: foodMap['name'],
          calories: foodMap['calories'],
        );
      }).toList();
    });
  }
  Future<void> retrieveAllFoods(int mealPlanId) async {
    final List<Map<String, dynamic>> foods = await DatabaseService().getFoodsForMealPlan(mealPlanId);
    setState(() {
      allFoods = foods.map((foodMap) {
        return FoodItem(
          id: foodMap['id'],
          name: foodMap['name'],
          calories: foodMap['calories'],
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Meal Plan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Selected Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
            ElevatedButton(
              onPressed: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2021),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: Text('Change Date'),
            ),
            DropdownButtonFormField<int>(
              value: selectedCalories,
              decoration: const InputDecoration(
                labelText: 'Select Target Calories',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem<int>(
                  value: 1500,
                  child: Text('1500 Calories'),
                ),
                DropdownMenuItem<int>(
                  value: 2000,
                  child: Text('2000 Calories'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCalories = value!;
                });
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: allFoods.length,
                itemBuilder: (context, index) {
                  final foodItem = allFoods[index];
                  final bool isSelected = selectedFoods.contains(foodItem);

                  return CheckboxListTile(
                    title: Text(foodItem.name),
                    value: isSelected,
                    onChanged: (newValue) {
                      setState(() {
                        if (newValue != null && newValue) {
                          selectedFoods.add(foodItem);
                        } else {
                          selectedFoods.remove(foodItem);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await DatabaseService().updateMealPlan(
                  widget.mealPlan['id'],
                  selectedDate,
                  selectedFoods,
                  selectedCalories,
                );
                Navigator.pop(context);
              },
              child: Text('Update Meal Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
