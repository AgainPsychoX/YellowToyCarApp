
# Yellow Toy Car App

The app, made using Flutter, is dedicated to controlling simple toy car based on ESP32-Cam module via WiFi.

See [YellowToyCar](https://github.com/AgainPsychoX/YellowToyCar) repository for the car project.





## To-do

* Send stop packets continuously when pressing stop button (for safety).
* Make drawer navigation nicer https://github.com/flutter/flutter/issues/26954
* Listen to connectivity changes https://stackoverflow.com/questions/25678216/android-internet-connectivity-change-listener 
* Work to be done on [`network_info_plus` package](https://pub.dev/packages/network_info_plus)
	+ Fix bug: `getWifiName` returns last connected name if disconnected. Make it return empty string if disconnected and/or add WiFi status to API.
	+ Add WiFi RSSI
	+ Allow observe (stream?) on updates
* Make basic controls arrow buttons rounded. Make lerping/adding border styles, like [`BeveledRectangleBorder`](https://github.com/flutter/flutter/blob/7048ed95a5ad3e43d697e0c397464193991fc230/packages/flutter/lib/src/painting/beveled_rectangle_border.dart#L51) possible.
* ...


