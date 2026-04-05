package com.xiaobaozi.ai_play_pokemon.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 游戏数据查询服务
 *
 * 从 pokeemerald 数据文件加载 ID 到名称的映射
 */
@Service
public class GameDataLookupService {

    private static final Logger log = LoggerFactory.getLogger(GameDataLookupService.class);

    @Value("${gamedata.species.path:pokeemerald/tools/inject_ui/js/data/species.js}")
    private String speciesDataPath;

    @Value("${gamedata.moves.path:pokeemerald/tools/inject_ui/js/data/moves.js}")
    private String movesDataPath;

    private Map<Integer, String> speciesNames = new HashMap<>();
    private Map<Integer, String> moveNames = new HashMap<>();

    // 匹配 { id: 1, name: 'SPECIES_BULBASAUR', display: 'Bulbasaur' }
    private static final Pattern DATA_PATTERN = Pattern.compile(
            "\\{\\s*id:\\s*(\\d+),\\s*name:\\s*'([^']+)',\\s*display:\\s*'([^']+)'\\s*\\}"
    );

    @PostConstruct
    public void init() {
        loadSpeciesData();
        loadMovesData();
        log.info("[GameDataLookupService] 加载完成: {} species, {} moves",
                speciesNames.size(), moveNames.size());
    }

    /**
     * 加载 species 数据
     */
    private void loadSpeciesData() {
        try {
            loadDataFile(speciesDataPath, speciesNames, "species");
            log.info("[GameDataLookupService] 加载 species 数据: {} 条", speciesNames.size());
        } catch (Exception e) {
            log.error("[GameDataLookupService] 加载 species 数据失败: {}", e.getMessage());
        }
    }

    /**
     * 加载 moves 数据
     */
    private void loadMovesData() {
        try {
            loadDataFile(movesDataPath, moveNames, "moves");
            log.info("[GameDataLookupService] 加载 moves 数据: {} 条", moveNames.size());
        } catch (Exception e) {
            log.error("[GameDataLookupService] 加载 moves 数据失败: {}", e.getMessage());
        }
    }

    /**
     * 解析 JS 数据文件
     */
    private void loadDataFile(String filePath, Map<Integer, String> targetMap, String dataType) throws IOException {
        try (BufferedReader reader = new BufferedReader(new FileReader(filePath))) {
            String line;
            while ((line = reader.readLine()) != null) {
                Matcher matcher = DATA_PATTERN.matcher(line);
                if (matcher.find()) {
                    int id = Integer.parseInt(matcher.group(1));
                    String display = matcher.group(3);
                    targetMap.put(id, display);
                }
            }
        }
    }

    /**
     * 获取 species 名称
     */
    public String getSpeciesName(int id) {
        return speciesNames.getOrDefault(id, "Species_" + id);
    }

    /**
     * 获取 move 名称
     */
    public String getMoveName(int id) {
        return moveNames.getOrDefault(id, "Move_" + id);
    }

    /**
     * 获取 species 名称（带 ID）
     */
    public String getSpeciesNameWithId(int id) {
        String name = speciesNames.get(id);
        if (name != null) {
            return name + " (" + id + ")";
        }
        return "Species_" + id;
    }

    /**
     * 获取 move 名称（带 ID）
     */
    public String getMoveNameWithId(int id) {
        String name = moveNames.get(id);
        if (name != null) {
            return name + " (" + id + ")";
        }
        return "Move_" + id;
    }

    /**
     * 检查服务是否可用
     */
    public boolean isAvailable() {
        return !speciesNames.isEmpty() && !moveNames.isEmpty();
    }
}
