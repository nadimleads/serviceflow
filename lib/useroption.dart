import 'package:flutter/material.dart';
import 'package:serviceflow/ceo/login_ceo.dart';

class Useroption extends StatelessWidget {
  const Useroption({super.key});

  @override
  Widget build(BuildContext useroptioncontext) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Option'),
        backgroundColor: const Color.fromARGB(45, 255, 255, 255),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 255, 188, 5),
              Colors.white,
              const Color.fromARGB(255, 255, 170, 0),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: const Text(
                        'Choose Your Role',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text(
                          'How would you like to access the system?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    //CEO login
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            useroptioncontext,
                            MaterialPageRoute(builder: (ceolog) => LoginCEO()),
                          );
                        },
                        label: const Padding(
                          padding: EdgeInsets.all(15),
                          child: Text(
                            'THE CEO     ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 219, 51, 0),
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons.manage_accounts_outlined,
                          size: 30,

                          color: Color.fromARGB(255, 0, 94, 255),
                        ),
                      ),
                    ),

                    //TEAMMATE Portion
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigator.push(
                            //   useroptioncontext,
                            //   MaterialPageRoute(
                            //     builder: (restlog) => RestaurantLogin(),
                            //   ),
                            // );
                          },
                          label: const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Text(
                              'TEAMMATES',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Color.fromARGB(255, 0, 91, 56),
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons.person_pin_rounded,
                            size: 30,
                            color: Color.fromARGB(255, 0, 191, 255),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
