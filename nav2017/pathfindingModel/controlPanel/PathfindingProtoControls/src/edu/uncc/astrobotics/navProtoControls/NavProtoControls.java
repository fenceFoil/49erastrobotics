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
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComponent;

import java.awt.GridBagLayout;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.BorderLayout;
import javax.swing.ScrollPaneConstants;

public class NavProtoControls extends JFrame {

	private JPanel contentPane;
	private JPanel sliderControlsPanel;

	// Preferences stuff. Static singleton for whole project.
	private static Preferences prefs;
	private JPanel mainPanel;
	private JScrollPane scrollPane;

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
		contentPane.setLayout(new BorderLayout(0, 0));

		scrollPane = new JScrollPane();
		scrollPane.setVerticalScrollBarPolicy(ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS);
		scrollPane.setHorizontalScrollBarPolicy(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_NEVER);
		contentPane.add(scrollPane);

		mainPanel = new JPanel();
		scrollPane.setViewportView(mainPanel);
		mainPanel.setLayout(new BorderLayout(0, 0));

		sliderControlsPanel = new JPanel();
		mainPanel.add(sliderControlsPanel, BorderLayout.CENTER);
		sliderControlsPanel.setLayout(new BoxLayout(sliderControlsPanel, BoxLayout.PAGE_AXIS));

		JButton btnReconnect = new JButton("Reconnect");
		mainPanel.add(btnReconnect, BorderLayout.SOUTH);
		final JFrame thisFrame = this;
		btnReconnect.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				sliderControlsPanel.removeAll();
				VisualizerClient.connectToServer(thisFrame);
				createSliderControls();
				pack();
			}
		});

		createSliderControls();
		pack();
	}
	
	/**
	 * Override window packing to make the window a reasonable height.
	 */

	@Override
	public void pack() {
		super.pack();
		setSize(getSize().width, Toolkit.getDefaultToolkit().getScreenSize().height / 5 * 4);
	}

	private void createSliderControls() {
		NavProtoConfig config = NavProtoConfig.readConfig();
		List<JComponent> controls = config.createControls();

		for (JComponent panel : controls) {
			sliderControlsPanel.add(panel, null);
		}
	}

}
