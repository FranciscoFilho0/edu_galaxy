import 'package:flutter/foundation.dart';
import '../models/room_model.dart';

class CurrentRoomController extends ChangeNotifier {

  RoomModel? _currentRoom;

  RoomModel? get currentRoom => _currentRoom;


  void selectRoom(RoomModel room) {

    _currentRoom = room;

    notifyListeners();

  }


  void clear() {

    _currentRoom = null;

    notifyListeners();

  }

}