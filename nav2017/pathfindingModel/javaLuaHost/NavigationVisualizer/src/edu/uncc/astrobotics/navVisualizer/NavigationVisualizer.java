package edu.uncc.astrobotics.navVisualizer;

import java.awt.EventQueue;
import java.io.File;
import java.nio.file.Files;

import javax.swing.JFrame;

import org.luaj.vm2.Globals;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.Varargs;
import org.luaj.vm2.lib.jse.JsePlatform;

public class NavigationVisualizer {

	private JFrame frame;

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					NavigationVisualizer window = new NavigationVisualizer();
					window.frame.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	/**
	 * Create the application.
	 */
	public NavigationVisualizer() {
		initialize();
		Globals globals = JsePlatform.standardGlobals();
		// LuaValue chunk = globals.load("function asdf () return 'yo' end");
		LuaValue chunk = globals.loadfile("../../lua/robotinfo.lua");
		System.out.println(chunk.invokemethod("robotinfo.getCorners()",
				LuaValue.varargsOf(LuaValue.valueOf(0), LuaValue.valueOf(0), LuaValue.valueOf(0))));
	}

	/**
	 * Initialize the contents of the frame.
	 */
	private void initialize() {
		frame = new JFrame();
		frame.setBounds(100, 100, 450, 300);
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
	}

}
