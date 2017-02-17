package edu.uncc.astrobotics.navProtoControls;

import java.awt.EventQueue;
import java.awt.FlowLayout;
import java.awt.Toolkit;
import java.util.List;
import java.util.prefs.Preferences;

import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.border.EmptyBorder;

import edu.uncc.astrobotics.navProtoControls.config.NavProtoConfig;
import javax.swing.BoxLayout;
import java.awt.GridBagLayout;

public class NavProtoControls extends JFrame {

	private JPanel contentPane;
	private JPanel sliderControlsPanel;

	// Preferences stuff. Static singleton for whole project.
	private static Preferences prefs;

	public static Preferences getPrefs() {
		return prefs;
	}

	static {
		prefs = Preferences.userNodeForPackage(NavProtoControls.class);
	}

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					VisualizerClient.connectToServer(null);
					NavProtoControls frame = new NavProtoControls();
					frame.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	/**
	 * Create the frame.
	 */
	public NavProtoControls() {
		setIconImage(Toolkit.getDefaultToolkit()
				.getImage(NavProtoControls.class.getResource("/edu/uncc/astrobotics/navProtoControls/icon.png")));
		setTitle("NASA RMC 2017 - Astrobotics - Navigation Prototype Controls");
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setBounds(100, 100, 450, 300);
		contentPane = new JPanel();
		contentPane.setBorder(new EmptyBorder(5, 5, 5, 5));
		setContentPane(contentPane);
		contentPane.setLayout(new FlowLayout(FlowLayout.CENTER, 5, 5));
		
				sliderControlsPanel = new JPanel();
				contentPane.add(sliderControlsPanel);
				sliderControlsPanel.setLayout(new BoxLayout(sliderControlsPanel, BoxLayout.PAGE_AXIS));

		createSliderControls();
	}

	private void createSliderControls() {
		NavProtoConfig config = NavProtoConfig.readConfig();
		List<JPanel> controls = config.createControls();

		for (JPanel panel : controls) {
			sliderControlsPanel.add(panel, null);
		}
	}

}
