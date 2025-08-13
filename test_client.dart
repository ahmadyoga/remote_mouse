import 'dart:io';
import 'dart:convert';

// Simple test client to simulate mobile app sending gestures
void main() async {
  print('🧪 Testing Remote Mouse Connection...');
  
  try {
    // Connect to the desktop server
    final socket = await Socket.connect('localhost', 1978);
    print('✅ Connected to desktop server');
    
    // Send a test mouse movement
    final moveEvent = {
      'dx': 10.0,
      'dy': 5.0,
    };
    
    final moveJson = json.encode(moveEvent);
    print('📤 Sending mouse move: $moveJson');
    socket.write(moveJson);
    await socket.flush();
    
    await Future.delayed(Duration(seconds: 1));
    
    // Send a test click
    final clickEvent = {
      'click': 'left',
    };
    
    final clickJson = json.encode(clickEvent);
    print('📤 Sending mouse click: $clickJson');
    socket.write(clickJson);
    await socket.flush();
    
    await Future.delayed(Duration(seconds: 1));
    
    // Send a test scroll
    final scrollEvent = {
      'scroll': 'up',
    };
    
    final scrollJson = json.encode(scrollEvent);
    print('📤 Sending mouse scroll: $scrollJson');
    socket.write(scrollJson);
    await socket.flush();
    
    print('✅ Test commands sent successfully');
    
    await socket.close();
    print('🔌 Connection closed');
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}
