"""Device-side transports. Each one is non-blocking: `poll()` returns the
messages received since the last call, `send()` goes to the current peer."""
from __future__ import annotations

import socket
import threading
from typing import Any, Callable, List, Optional, Tuple

from .protocol import (BLE_RX, BLE_SERVICE, BLE_TX, RADIO_PROFILES, UDP_ANNOUNCE_PORT, UDP_DEVICE_PORT, LineDecoder, Msg, decode,
                       encode, module_rate_hz)


class Transport:
    name = "transport"
    #: False on telemetry-only links: only stop, ping, rate and bye are accepted.
    accepts_control = True
    #: Radio links: no point clouds or tracks, state every 2 s.
    low_bandwidth = False
    #: Telemetry rate cap, 0 = none. At 2 Hz or less only the compact field set is sent.
    max_rate_hz = 0.0
    #: Radio profile id when this is a radio link.
    radio: Optional[str] = None

    def use_radio(self, radio: str) -> "Transport":
        """Apply a radio profile (`sik`, `lora`, `hc12`, `xbee`, `other`)."""
        if radio not in RADIO_PROFILES:
            raise ValueError(f"radio must be one of {tuple(RADIO_PROFILES)}")
        _, tlm, ctl = RADIO_PROFILES[radio]
        self.radio = radio
        self.low_bandwidth = True
        self.max_rate_hz = float(tlm)
        self.accepts_control = ctl > 0
        return self

    def use_module(self, baud: int) -> "Transport":
        """A serial bridge module (HM-10, HC-05, RN4870…) at `baud`: rates
        follow the baud rate, control is accepted."""
        self.low_bandwidth = True
        self.max_rate_hz = module_rate_hz(baud)
        self.accepts_control = True
        return self

    def poll(self) -> List[Msg]:
        raise NotImplementedError

    def send(self, m: Msg) -> None:
        raise NotImplementedError

    def announce(self, m: Msg) -> None:
        """Discovery info while no app is connected."""

    @property
    def has_peer(self) -> bool:
        return True

    def close(self) -> None:
        pass


class UdpTransport(Transport):
    """Wi-Fi / Ethernet: one JSON message per datagram on port 47800."""

    name = "wifi"

    def __init__(self, port: int = UDP_DEVICE_PORT, host: str = "0.0.0.0") -> None:
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        self.sock.bind((host, port))
        self.sock.setblocking(False)
        self.port = self.sock.getsockname()[1]
        self.peer: Optional[Tuple[str, int]] = None
        self._last_sender: Optional[Tuple[str, int]] = None

    def poll(self) -> List[Msg]:
        out: List[Msg] = []
        while True:
            try:
                data, addr = self.sock.recvfrom(65535)
            except (BlockingIOError, InterruptedError):
                break
            except OSError:
                break
            m = decode(data)
            if m is None:
                continue
            if m["t"] == "discover":
                self._last_sender = addr
                m["_from"] = addr
            elif m["t"] in ("hello", "pair"):
                self.peer = addr
            elif self.peer is None or addr != self.peer:
                # Commands only from the session peer.
                continue
            out.append(m)
        return out

    def send(self, m: Msg) -> None:
        if self.peer is None:
            return
        data = encode(m)
        if len(data) > 65000:
            return
        try:
            self.sock.sendto(data, self.peer)
        except OSError:
            pass

    def reply(self, m: Msg, addr: Tuple[str, int]) -> None:
        try:
            self.sock.sendto(encode(m), addr)
        except OSError:
            pass

    def announce(self, m: Msg) -> None:
        try:
            self.sock.sendto(encode(m), ("255.255.255.255", UDP_ANNOUNCE_PORT))
        except OSError:
            pass

    @property
    def has_peer(self) -> bool:
        return self.peer is not None

    def drop_peer(self) -> None:
        self.peer = None

    def close(self) -> None:
        self.sock.close()


class LineTransport(Transport):
    """Newline-delimited JSON over any byte stream. `read()` returns the bytes
    available now (b"" when none) and must not block."""

    name = "stream"

    def __init__(self, read: Callable[[], bytes], write: Callable[[bytes], Any], close: Optional[Callable[[], Any]] = None) -> None:
        self._read, self._write, self._close = read, write, close
        self._lines = LineDecoder()

    def poll(self) -> List[Msg]:
        try:
            data = self._read()
        except Exception:
            return []
        return list(self._lines.feed(data)) if data else []

    def send(self, m: Msg) -> None:
        try:
            self._write(encode(m) + b"\n")
        except Exception:
            pass

    def announce(self, m: Msg) -> None:
        # One peer on a wire or radio: announcing is just writing, so the app
        # can find the device behind a radio before pairing.
        self.send(m)

    def close(self) -> None:
        if self._close:
            self._close()


class SocketTransport(LineTransport):
    """A connected stream socket (TCP serial bridges such as ser2net, tests)."""

    name = "socket"

    def __init__(self, sock: socket.socket) -> None:
        sock.setblocking(False)
        self.sock = sock

        def read() -> bytes:
            try:
                return sock.recv(65536)
            except (BlockingIOError, InterruptedError):
                return b""

        super().__init__(read, sock.sendall, sock.close)


class SerialTransport(LineTransport):
    """USB serial or UART, newline-delimited JSON. Needs `pyserial`."""

    name = "serial"

    def __init__(self, path: str, baud: int = 115200, telemetry_only: bool = False) -> None:
        try:
            import serial  # type: ignore
        except ImportError as e:  # pragma: no cover
            raise ImportError('serial transport needs pyserial: pip install "koebelt-link[serial]"') from e
        self.port = serial.Serial(path, baud, timeout=0, write_timeout=0.05)

        def read() -> bytes:
            n = self.port.in_waiting
            return self.port.read(n) if n else b""

        super().__init__(read, self.port.write, self.port.close)
        if telemetry_only:
            self.use_radio("lora")


class RadioTransport(SerialTransport):
    """A radio modem on a serial port: SiK, HC-12, XBee or a LoRa UART module.
    The radio profile sets the baud rate (unless given) and the link rates."""

    name = "radio"

    def __init__(self, path: str, radio: str = "sik", baud: Optional[int] = None) -> None:
        if radio not in RADIO_PROFILES:
            raise ValueError(f"radio must be one of {tuple(RADIO_PROFILES)}")
        super().__init__(path, baud or RADIO_PROFILES[radio][0])
        self.use_radio(radio)


class BleTransport(Transport):
    """BLE peripheral with the Nordic-UART-style koebelt/link service. Needs `bless`.

    bless is asyncio-based, so it runs on a background event loop thread."""

    name = "ble"

    def __init__(self, name: str) -> None:
        try:
            import asyncio

            from bless import BlessServer, GATTAttributePermissions, GATTCharacteristicProperties  # type: ignore
        except ImportError as e:  # pragma: no cover
            raise ImportError('BLE transport needs bless: pip install "koebelt-link[ble]"') from e
        self._asyncio = asyncio
        self._lines = LineDecoder()
        self._inbox: List[Msg] = []
        self._lock = threading.Lock()
        self._loop = asyncio.new_event_loop()
        self._ready = threading.Event()
        self._connected = False

        def on_write(char: Any, value: Any, **_: Any) -> None:
            if str(char.uuid).lower() != BLE_RX:
                return
            self._connected = True
            with self._lock:
                self._inbox.extend(self._lines.feed(bytes(value)))

        async def setup() -> None:
            self.server = BlessServer(name=name, loop=self._loop)
            self.server.write_request_func = on_write
            await self.server.add_new_service(BLE_SERVICE)
            await self.server.add_new_characteristic(
                BLE_SERVICE, BLE_RX,
                GATTCharacteristicProperties.write | GATTCharacteristicProperties.write_without_response,
                None, GATTAttributePermissions.writeable,
            )
            await self.server.add_new_characteristic(
                BLE_SERVICE, BLE_TX, GATTCharacteristicProperties.notify, None, GATTAttributePermissions.readable,
            )
            await self.server.start()
            self._ready.set()

        def run() -> None:
            asyncio.set_event_loop(self._loop)
            self._loop.run_until_complete(setup())
            self._loop.run_forever()

        threading.Thread(target=run, daemon=True, name="koebelt-ble").start()
        self._ready.wait(10)

    def poll(self) -> List[Msg]:
        with self._lock:
            out, self._inbox = self._inbox, []
        return out

    def send(self, m: Msg) -> None:
        if not self._connected:
            return
        data = encode(m) + b"\n"

        def push() -> None:
            ch = self.server.get_characteristic(BLE_TX)
            for i in range(0, len(data), 180):
                ch.value = bytearray(data[i : i + 180])
                self.server.update_value(BLE_SERVICE, BLE_TX)

        self._loop.call_soon_threadsafe(push)

    @property
    def has_peer(self) -> bool:
        return self._connected

    def close(self) -> None:
        async def stop() -> None:
            await self.server.stop()

        self._asyncio.run_coroutine_threadsafe(stop(), self._loop)


__all__ = ["Transport", "UdpTransport", "LineTransport", "SocketTransport", "SerialTransport", "RadioTransport", "BleTransport"]
