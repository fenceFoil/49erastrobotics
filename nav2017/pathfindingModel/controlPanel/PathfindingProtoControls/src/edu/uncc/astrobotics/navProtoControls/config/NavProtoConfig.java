package edu.uncc.astrobotics.navProtoControls.config;

import java.io.IOException;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.LinkedList;
import java.util.List;

import javax.swing.JPanel;

import com.fasterxml.jackson.databind.ObjectMapper;

import edu.uncc.astrobotics.navProtoControls.JNavValueSlider;

public class NavProtoConfig {
	private List<SliderConfig> sliders;

	public static NavProtoConfig readConfig() {
		// read json file data to String
		byte[] jsonData = null;
		try {
			try {
				jsonData = Files.readAllBytes(Paths.get(NavProtoConfig.class.getResource("sliders.json").toURI()));
			} catch (URISyntaxException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return null;
		}

		// create ObjectMapper instance
		ObjectMapper objectMapper = new ObjectMapper();

		// convert json string to object
		try {
			return objectMapper.readValue(jsonData, NavProtoConfig.class);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return null;
		}
	}

	public List<JPanel> createControls() {
		LinkedList<JPanel> controls = new LinkedList<>();

		for (SliderConfig config : sliders) {
			JNavValueSlider slider = new JNavValueSlider(config.getVariable(), config.getDefaultMin(),
					config.getDefaultMax(), config.getDefaultValue());
			controls.add(slider);
		}

		return controls;
	}

	@Override
	public String toString() {
		return "NavProtoConfig [sliders=" + sliders + "]";
	}

	public List<SliderConfig> getSliders() {
		return sliders;
	}

	public void setSliders(List<SliderConfig> sliders) {
		this.sliders = sliders;
	}

	public static void main(String[] args) {
		System.out.println(readConfig());
	}
}
