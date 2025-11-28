import json
import os
import subprocess
from pathlib import Path
from typing import Dict, List, Optional

from PyQt5 import QtCore, QtGui, QtWidgets


CONFIG_PATH = Path("screens.json")
DEFAULT_HOST = "127.0.0.1"


class AdbFinder:
    """Locate adb.exe with heuristics tailored for MuMuPlayer."""

    COMMON_CANDIDATES: List[Path] = [
        Path(os.environ.get("ADB_PATH", "")) if os.environ.get("ADB_PATH") else None,
        Path("C:/Program Files/Netease/MuMuPlayer/nx_device/12.0/shell/adb.exe"),
        Path("C:/Program Files (x86)/Netease/MuMuPlayer/nx_device/12.0/shell/adb.exe"),
        Path("D:/Program Files/Netease/MuMuPlayer/nx_device/12.0/shell/adb.exe"),
        Path("D:/Program Files (x86)/Netease/MuMuPlayer/nx_device/12.0/shell/adb.exe"),
        Path("C:/MuMuPlayer-12/nx_device/12.0/shell/adb.exe"),
        Path("D:/MuMuPlayer-12/nx_device/12.0/shell/adb.exe"),
    ]

    SCAN_ROOTS: List[Path] = [
        Path("C:/Program Files"),
        Path("C:/Program Files (x86)"),
        Path("C:/MuMuPlayer-12"),
        Path("D:/Program Files"),
        Path("D:/Program Files (x86)"),
        Path("D:/MuMuPlayer-12"),
    ]

    def __init__(self) -> None:
        self._cached_path: Optional[Path] = None

    def find_adb(self) -> Optional[Path]:
        if self._cached_path and self._cached_path.exists():
            return self._cached_path

        for candidate in self.COMMON_CANDIDATES:
            if candidate and candidate.is_file():
                self._cached_path = candidate
                return candidate

        for root in self.SCAN_ROOTS:
            if not root.exists():
                continue
            result = self._scan_for_adb(root)
            if result:
                self._cached_path = result
                return result
        return None

    def _scan_for_adb(self, root: Path) -> Optional[Path]:
        for path in root.rglob("adb.exe"):
            return path
        return None


class ScreenConfig:
    def __init__(self, name: str, host: str, port: str, general_url: str, private_url: str):
        self.name = name
        self.host = host
        self.port = port
        self.general_url = general_url
        self.private_url = private_url

    def to_dict(self) -> Dict[str, str]:
        return {
            "name": self.name,
            "host": self.host,
            "port": self.port,
            "general_url": self.general_url,
            "private_url": self.private_url,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, str]) -> "ScreenConfig":
        return cls(
            name=data.get("name", ""),
            host=data.get("host", DEFAULT_HOST),
            port=data.get("port", "5554"),
            general_url=data.get("general_url", ""),
            private_url=data.get("private_url", ""),
        )


class MainWindow(QtWidgets.QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("Roblox Auto Join - MuMuPlayer12")
        self.resize(640, 480)

        self.adb_finder = AdbFinder()
        self.configs: List[ScreenConfig] = []

        central = QtWidgets.QWidget()
        self.setCentralWidget(central)
        layout = QtWidgets.QVBoxLayout()
        central.setLayout(layout)

        self.adb_status = QtWidgets.QLabel("กำลังค้นหา ADB...")
        layout.addWidget(self.adb_status)

        self.screen_list = QtWidgets.QListWidget()
        self.screen_list.itemSelectionChanged.connect(self.populate_fields)
        layout.addWidget(self.screen_list)

        form_layout = QtWidgets.QFormLayout()
        layout.addLayout(form_layout)

        self.name_input = QtWidgets.QLineEdit()
        form_layout.addRow("ชื่อจอ:", self.name_input)

        self.host_input = QtWidgets.QLineEdit(DEFAULT_HOST)
        self.host_input.setReadOnly(True)
        form_layout.addRow("Host:", self.host_input)

        self.port_input = QtWidgets.QLineEdit("5554")
        form_layout.addRow("พอร์ต:", self.port_input)

        self.general_url_input = QtWidgets.QLineEdit()
        form_layout.addRow("URL แมพทั่วไป:", self.general_url_input)

        self.private_url_input = QtWidgets.QLineEdit()
        form_layout.addRow("URL เซิร์ฟไพรเวท:", self.private_url_input)

        button_layout = QtWidgets.QHBoxLayout()
        layout.addLayout(button_layout)

        self.add_button = QtWidgets.QPushButton("เพิ่มจอ")
        self.add_button.clicked.connect(self.add_screen)
        button_layout.addWidget(self.add_button)

        self.update_button = QtWidgets.QPushButton("แก้ไขจอ")
        self.update_button.clicked.connect(self.update_screen)
        button_layout.addWidget(self.update_button)

        self.delete_button = QtWidgets.QPushButton("ลบจอ")
        self.delete_button.clicked.connect(self.delete_screen)
        button_layout.addWidget(self.delete_button)

        self.refresh_adb_button = QtWidgets.QPushButton("ค้นหา ADB อีกครั้ง")
        self.refresh_adb_button.clicked.connect(self.refresh_adb_path)
        layout.addWidget(self.refresh_adb_button)

        self.launch_button = QtWidgets.QPushButton("เชื่อมต่อ & เข้าเกม")
        self.launch_button.clicked.connect(self.connect_and_launch)
        layout.addWidget(self.launch_button)

        self.status_bar = QtWidgets.QStatusBar()
        self.setStatusBar(self.status_bar)

        self.load_configs()
        self.refresh_adb_path()

    def load_configs(self) -> None:
        if CONFIG_PATH.exists():
            try:
                data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
                self.configs = [ScreenConfig.from_dict(item) for item in data]
                for cfg in self.configs:
                    self.screen_list.addItem(cfg.name)
            except json.JSONDecodeError:
                self.status_bar.showMessage("ไม่สามารถอ่านไฟล์ screens.json ได้", 5000)

    def save_configs(self) -> None:
        data = [cfg.to_dict() for cfg in self.configs]
        CONFIG_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

    def populate_fields(self) -> None:
        item = self.screen_list.currentItem()
        if not item:
            return
        cfg = next((c for c in self.configs if c.name == item.text()), None)
        if not cfg:
            return
        self.name_input.setText(cfg.name)
        self.host_input.setText(cfg.host)
        self.port_input.setText(cfg.port)
        self.general_url_input.setText(cfg.general_url)
        self.private_url_input.setText(cfg.private_url)

    def refresh_adb_path(self) -> None:
        adb_path = self.adb_finder.find_adb()
        if adb_path:
            self.adb_status.setText(f"พบ ADB: {adb_path}")
        else:
            self.adb_status.setText("ไม่พบ ADB.exe ในไดรฟ์ C หรือ D")

    def add_screen(self) -> None:
        name = self.name_input.text().strip()
        if not name:
            QtWidgets.QMessageBox.warning(self, "ข้อมูลไม่ครบ", "กรุณากรอกชื่อจอ")
            return
        if any(cfg.name == name for cfg in self.configs):
            QtWidgets.QMessageBox.warning(self, "ชื่อซ้ำ", "มีชื่อนี้อยู่แล้ว")
            return
        cfg = ScreenConfig(
            name=name,
            host=self.host_input.text().strip() or DEFAULT_HOST,
            port=self.port_input.text().strip() or "5554",
            general_url=self.general_url_input.text().strip(),
            private_url=self.private_url_input.text().strip(),
        )
        self.configs.append(cfg)
        self.screen_list.addItem(cfg.name)
        self.save_configs()
        self.status_bar.showMessage("เพิ่มจอใหม่แล้ว", 3000)

    def update_screen(self) -> None:
        item = self.screen_list.currentItem()
        if not item:
            QtWidgets.QMessageBox.warning(self, "ไม่พบจอ", "กรุณาเลือกจอที่ต้องการแก้ไข")
            return
        name = self.name_input.text().strip()
        if not name:
            QtWidgets.QMessageBox.warning(self, "ข้อมูลไม่ครบ", "กรุณากรอกชื่อจอ")
            return
        existing = next((c for c in self.configs if c.name == item.text()), None)
        if not existing:
            return
        if name != existing.name and any(c.name == name for c in self.configs):
            QtWidgets.QMessageBox.warning(self, "ชื่อซ้ำ", "มีชื่อนี้อยู่แล้ว")
            return
        existing.name = name
        existing.host = self.host_input.text().strip() or DEFAULT_HOST
        existing.port = self.port_input.text().strip() or "5554"
        existing.general_url = self.general_url_input.text().strip()
        existing.private_url = self.private_url_input.text().strip()
        item.setText(existing.name)
        self.save_configs()
        self.status_bar.showMessage("บันทึกการแก้ไขแล้ว", 3000)

    def delete_screen(self) -> None:
        item = self.screen_list.currentItem()
        if not item:
            QtWidgets.QMessageBox.warning(self, "ไม่พบจอ", "กรุณาเลือกจอที่ต้องการลบ")
            return
        name = item.text()
        self.configs = [c for c in self.configs if c.name != name]
        self.screen_list.takeItem(self.screen_list.row(item))
        self.save_configs()
        self.status_bar.showMessage("ลบจอแล้ว", 3000)

    def connect_and_launch(self) -> None:
        adb_path = self.adb_finder.find_adb()
        if not adb_path:
            QtWidgets.QMessageBox.critical(self, "ไม่พบ ADB", "ค้นหา ADB.exe ในไดรฟ์ C หรือ D ไม่สำเร็จ")
            return

        item = self.screen_list.currentItem()
        if not item:
            QtWidgets.QMessageBox.warning(self, "ไม่พบจอ", "กรุณาเลือกจอก่อนเริ่ม")
            return
        cfg = next((c for c in self.configs if c.name == item.text()), None)
        if not cfg:
            QtWidgets.QMessageBox.warning(self, "ข้อมูลไม่ครบ", "กรุณาเลือกจอใหม่อีกครั้ง")
            return

        url = cfg.private_url or cfg.general_url or self.general_url_input.text().strip()
        if not url:
            QtWidgets.QMessageBox.warning(self, "ไม่มี URL", "กรุณากรอก URL แมพก่อนเข้าเกม")
            return

        target = f"{cfg.host}:{cfg.port}"
        connect_result = subprocess.run(
            [str(adb_path), "connect", target], capture_output=True, text=True
        )
        if connect_result.returncode != 0:
            QtWidgets.QMessageBox.critical(
                self,
                "เชื่อมต่อไม่สำเร็จ",
                f"เชื่อมต่อ {target} ไม่สำเร็จ:\n{connect_result.stderr or connect_result.stdout}",
            )
            return

        launch_result = subprocess.run(
            [str(adb_path), "shell", "am", "start", "-a", "android.intent.action.VIEW", "-d", url],
            capture_output=True,
            text=True,
        )
        if launch_result.returncode != 0:
            QtWidgets.QMessageBox.critical(
                self,
                "เปิดแมพไม่สำเร็จ",
                launch_result.stderr or launch_result.stdout,
            )
            return

        self.status_bar.showMessage(f"เปิดแมพแล้วผ่าน {target}", 5000)


def main() -> None:
    app = QtWidgets.QApplication([])
    window = MainWindow()
    window.show()
    app.exec_()


if __name__ == "__main__":
    main()
