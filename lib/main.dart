import 'package:flutter/material.dart';
import 'package:sql_example/db/database.dart';
import 'package:sql_example/model/student.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Записная книжка',
      home: StudentPage(),
    );
  }
}

class StudentPage extends StatefulWidget {
  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final GlobalKey<FormState> _formStateKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();

  late Future<List<Student>> _studentsList;
  late String _studentName;
  bool isUpdate = false;
  int? studentIdForUpdate;

  @override
  void initState() {
    super.initState();
    updateStudentList();
  }

  updateStudentList() {
    setState(() {
      _studentsList = DBProvider.db.getStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Записная книжка'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: <Widget>[
          Form(
            key: _formStateKey,
            autovalidateMode: AutovalidateMode.always,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null) {
                        return 'Введите имя клиента';
                      }
                      if (value.trim() == "") return "ОШИБКА! ВВЕДИТЕ ТЕКСТ";
                      return null;
                    },
                    onSaved: (value) {
                      _studentName = value!;
                    },
                    controller: _studentNameController,
                    decoration: InputDecoration(
                      focusedBorder: new UnderlineInputBorder(
                        borderSide: new BorderSide(
                            color: Colors.greenAccent,
                            width: 2,
                            style: BorderStyle.solid),
                      ),
                      labelText: "Имя клиента и телефон",
                      icon: Icon(
                        Icons.people,
                        color: Colors.black,
                      ),
                      fillColor: Colors.white,
                      labelStyle: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.green,
                  textStyle: TextStyle(color: Colors.white),
                ),
                child: Text(
                  (isUpdate ? 'ОБНОВИТЬ' : 'ДОБАВИТЬ'),
                ),
                onPressed: () {
                  if (isUpdate) {
                    if (_formStateKey.currentState!.validate()) {
                      _formStateKey.currentState!.save();
                      DBProvider.db
                          .updateStudent(
                              Student(studentIdForUpdate!, _studentName))
                          .then((data) {
                        setState(() {
                          isUpdate = false;
                        });
                      });
                    }
                  } else {
                    if (_formStateKey.currentState!.validate()) {
                      _formStateKey.currentState!.save();
                      // DBProvider.db.insertStudent(Student(null, _studentName));
                      DBProvider.db.insertStudent(Student(null, _studentName));
                    }
                  }
                  _studentNameController.text = '';
                  updateStudentList();
                },
              ),
              Padding(
                padding: EdgeInsets.all(10),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.red,
                  textStyle: TextStyle(color: Colors.white),
                ),
                child: Text(
                  (isUpdate ? 'НЕ ОБНОВЛЯТЬ' : 'УБРАТЬ'),
                ),
                onPressed: () {
                  _studentNameController.text = '';
                  setState(() {
                    isUpdate = false;
                    studentIdForUpdate = null; // null;
                  });
                },
              ),
            ],
          ),
          const Divider(
            height: 5.0,
          ),
          Expanded(
            child: FutureBuilder(
              future: _studentsList,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return generateList(snapshot.data as List<Student>);
                }
                if (snapshot.data == null ||
                    (snapshot.data as List<Student>).length == 0) {
                  return Text('Нет данных');
                }
                return CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
    );
  }

  SingleChildScrollView generateList(List<Student> students) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: DataTable(
          headingRowColor: MaterialStateColor.resolveWith(
              (states) => Colors.lightGreenAccent.shade100),
          columns: [
            DataColumn(
              label: Text('ИМЯ/ТЕЛЕФОН'),
            ),
            DataColumn(
              label: Text('УДАЛИТЬ'),
            ),
          ],
          rows: students
              .map(
                (student) => DataRow(cells: [
                  DataCell(Text(student.name), onTap: () {
                    setState(() {
                      isUpdate = true;
                      studentIdForUpdate = student.id;
                    });
                    _studentNameController.text = student.name;
                  }),
                  DataCell(
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        DBProvider.db.deleteStudent(student.id);
                        updateStudentList();
                      },
                    ),
                  ),
                ]),
              )
              .toList(),
        ),
      ),
    );
  }
}
