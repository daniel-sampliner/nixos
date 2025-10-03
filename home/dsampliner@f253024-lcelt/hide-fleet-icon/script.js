// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const hideItem = "systray_@PID@";

for (const panel of panels()) {
	for (const widget of panel.widgets(["org.kde.plasma.systemtray"])) {
		widget.currentConfigGroup = ["General"];
		const hiddenItems = new Set(
			widget
			.readConfig("hiddenItems")
			?.split(",")
			.filter(
				(item) => !/^systray_[0-9]+$/.test(item)
			) ?? [],
		);

		hiddenItems.add(hideItem);

		widget.writeConfig("hiddenItems", [...hiddenItems]);
		widget.reloadConfig();
	}
}
