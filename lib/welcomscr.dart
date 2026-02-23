import 'package:flutter/material.dart';
import 'package:serviceflow/auth/login.dart';

var start = Alignment.topLeft;
var end = Alignment.bottomRight;

class Welcomescreen extends StatelessWidget {
  const Welcomescreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            //C->d->B->g
            colors: const [
              Color.fromARGB(255, 255, 221, 111),
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 186, 11),
            ],
            begin: start,
            end: end,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.miscellaneous_services_rounded,
                size: 80,
                color: Color.fromARGB(255, 0, 3, 101),
              ),

              Padding(
                padding: const EdgeInsets.all(10.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown, // scales text down if needed
                  child: const Text(
                    'Welcome to ServiceFlow',
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontWeight: FontWeight.bold,
                      fontSize: 30, // acts as a "max size"
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text(
                    'The Smart way to Track Service',
                    style: TextStyle(
                      fontSize: 17,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontFamily: 'Arial',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: 150, // enough width for text + padding
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (wlcmctx) => Login()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 3, 85),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.sensor_occupied_rounded, size: 22),
                  label: const Text(
                    'Enter App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Arial',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Let\'s make the Service Easy!',
                style: TextStyle(
                  fontSize: 10,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
