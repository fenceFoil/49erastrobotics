package edu.uncc.astrobotics.navProtoControls;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.net.UnknownHostException;

import javax.swing.JFrame;
import javax.swing.JOptionPane;

public class VisualizerClient {
	public static final int PORT_NUM = 31336;

	private static Socket socket;

	private static BufferedWriter socketOut;

	public static void connectToServer(JFrame frame) {
		// Try to connect to localhost at port 31336
		try {
			socket = new Socket("localhost", PORT_NUM);
		} catch (UnknownHostException e) {
			// Can't happen. It's localhost.
			e.printStackTrace();
		} catch (IOException e) {
			// e.printStackTrace();
			while (socket == null || !socket.isConnected()) {
				String enteredValue = (String) JOptionPane.showInputDialog(frame,
						"Enter IP Address of Navigation Prototype Server:", "Connecting to Visualizer",
						JOptionPane.PLAIN_MESSAGE, null, null,
						NavProtoControls.getPrefs().get("serverIP", "localhost"));
				if (enteredValue == null) {
					// TODO: Quit application
					break;
				} else {
					try {
						socket = new Socket(enteredValue, PORT_NUM);
					} catch (IOException e1) {
						// Print stack trace if failed to connect, and let the
						// whole dialog loop iterate again.
						e1.printStackTrace();
					}
				}
			}
		}
		try {
			socketOut = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()));
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static void sendCode(String code) {
		try {
			socketOut.write(code);
			socketOut.newLine();
			socketOut.flush();
			System.out.println(code);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static void updateVariable(String variable, double value) {
		sendCode(variable + " = " + value);
	}
	
	public static void updateVariable(String variable, boolean value) {
		sendCode(variable + " = " + value);
	}

}
