/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package fr.insalyon.creatis.boutiquesvelocity;

import fr.insalyon.creatis.vip.applicationimporter.client.bean.BoutiquesTool;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Scanner;
import org.json.JSONObject;

/**
 *
 * @author Tristan Glatard
 */
public class Main {

    public static void main(String[] args) throws FileNotFoundException, IOException {

        HashMap<String, BoutiquesTool> btMaps = new HashMap<>();

        // Will eventually be passed to the method.
        String jsonDirectory = args[0];
        String outputDirectory = args[1];
        System.out.println("Reading JSON descriptors in " + jsonDirectory);

        // File names
        Path toolFileName = Paths.get(jsonDirectory, "tool.json");
        Path metricFileName = Paths.get(jsonDirectory, "SegPerfAnalyser.json");
        Path updaterFileName = Paths.get(jsonDirectory, "metadata-updater.json");

        // JSON strings
        String toolJSONString = new Scanner(new File(toolFileName.toString())).useDelimiter("\\Z").next();
        String metricJSONString = new Scanner(new File(metricFileName.toString())).useDelimiter("\\Z").next();
        String updaterJSONString = new Scanner(new File(updaterFileName.toString())).useDelimiter("\\Z").next();

        // JSON objects
        JSONObject toolJSONObject = new JSONObject(toolJSONString);
        JSONObject metricJSONObject = new JSONObject(metricJSONString);
        JSONObject updaterJSONObject = new JSONObject(updaterJSONString);

        // Boutiques Tools
        BoutiquesTool tool = JSONUtil.parseBoutiquesTool(toolJSONObject);
        BoutiquesTool metric = JSONUtil.parseBoutiquesTool(metricJSONObject);
        BoutiquesTool updater = JSONUtil.parseBoutiquesTool(updaterJSONObject);

        // Templates
        String wrapperTemplate = "vm/wrapper.vm";
        String gaswTemplate = "vm/gasw.vm";
        String gwendiaTemplate = "vm/gwendia_challenge_msseg.vm";

        // Tool map
        btMaps.put("tool", tool);
        btMaps.put("metric", metric);
        btMaps.put("adaptater", updater);

        // File generation
        BoutiquesTool[] tools = {tool, metric, updater};
        for (BoutiquesTool t : tools) {
            t.setApplicationLFN("/grid/biomed/creatis/vip/applications/" + t.getName());
            VelocityUtils.getInstance().createDocument(t, wrapperTemplate, Paths.get(outputDirectory, "bin", t.getName() + ".sh"));
            VelocityUtils.getInstance().createDocument(t, gaswTemplate, Paths.get(outputDirectory, "gasw", t.getName() + ".xml"));
        }
        VelocityUtils.getInstance().createDocument(btMaps, gwendiaTemplate, Paths.get(outputDirectory, "workflow", tool.getName() + ".gwendia"));
    }

}
