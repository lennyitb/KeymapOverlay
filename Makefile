APP_NAME := KeymapOverlay
DERIVED_DATA := $(HOME)/Library/Developer/Xcode/DerivedData

.PHONY: dmg

dmg: dmg/background.png dmg/volume_icon.icns
	bash dmg/build_dmg.sh

dmg/background.png: dmg/create_background.py
	python3 dmg/create_background.py

dmg/volume_icon.icns: dmg/create_volume_icon.py icon.png
	python3 dmg/create_volume_icon.py
