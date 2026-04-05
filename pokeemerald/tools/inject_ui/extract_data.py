#!/usr/bin/env python3
"""
生成完整的 bundle.js 数据文件
"""

import re
import os

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def extract_constants(file_path, prefix, exclude_patterns):
    constants = []
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            match = re.match(rf'#define\s+({prefix}\w+)\s+(\d+)', line)
            if match:
                name, value = match.group(1), int(match.group(2))
                if not any(p in name for p in exclude_patterns):
                    display = name.replace(prefix, '').replace('_', ' ').title()
                    constants.append({'id': value, 'name': name, 'display': display})
    return constants

def extract_species_abilities():
    file_path = os.path.join(ROOT_DIR, 'src/data/pokemon/species_info.h')
    ability_map = {}
    with open(os.path.join(ROOT_DIR, 'include/constants/abilities.h'), 'r', encoding='utf-8') as f:
        for line in f:
            m = re.match(r'#define\s+(ABILITY_\w+)\s+(\d+)', line)
            if m:
                ability_map[m.group(1)] = int(m.group(2))

    species_map = {}
    with open(os.path.join(ROOT_DIR, 'include/constants/species.h'), 'r', encoding='utf-8') as f:
        for line in f:
            m = re.match(r'#define\s+(SPECIES_\w+)\s+(\d+)', line)
            if m:
                species_map[m.group(1)] = int(m.group(2))

    result = {}
    current_species_id = None

    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            m = re.search(r'\[(SPECIES_\w+)\]', line)
            if m:
                current_species_id = species_map.get(m.group(1))
                continue
            if current_species_id is not None:
                m = re.search(r'\.abilities\s*=\s*\{(ABILITY_\w+),\s*(ABILITY_\w+)\}', line)
                if m:
                    ab1 = ability_map.get(m.group(1), 0)
                    ab2 = ability_map.get(m.group(2), 0)
                    result[current_species_id] = [ab1, ab2]
                    current_species_id = None
    return result

def main():
    species = extract_constants(os.path.join(ROOT_DIR, 'include/constants/species.h'), 'SPECIES_', ['SPECIES_NONE', 'SPECIES_EGG', 'SPECIES_UNOWN_'])
    moves = extract_constants(os.path.join(ROOT_DIR, 'include/constants/moves.h'), 'MOVE_', ['MOVE_NONE'])
    abilities = extract_constants(os.path.join(ROOT_DIR, 'include/constants/abilities.h'), 'ABILITY_', ['ABILITY_NONE'])
    items = extract_constants(os.path.join(ROOT_DIR, 'include/constants/items.h'), 'ITEM_', ['ITEM_NONE', 'ITEM_0'])
    species_abilities = extract_species_abilities()

    output_path = os.path.join(os.path.dirname(__file__), 'js', 'bundle.js')

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('// 自动生成 - 请勿手动编辑\n\n')

        # Species
        f.write('const SPECIES_DATA = [null,\n')
        for s in species:
            f.write(f'  {{id:{s["id"]},display:"{s["display"]}"}},\n')
        f.write('];\n\n')

        # Moves
        f.write('const MOVES_DATA = [null,\n')
        for m in moves:
            f.write(f'  {{id:{m["id"]},display:"{m["display"]}"}},\n')
        f.write('];\n\n')

        # Abilities
        f.write('const ABILITIES_DATA = [null,\n')
        for a in abilities:
            f.write(f'  {{id:{a["id"]},display:"{a["display"]}"}},\n')
        f.write('];\n\n')

        # Items
        f.write('const ITEMS_DATA = [null,\n')
        for i in items:
            f.write(f'  {{id:{i["id"]},display:"{i["display"]}"}},\n')
        f.write('];\n\n')

        # Species Abilities
        f.write('const SPECIES_ABILITIES = {\n')
        for sid, abs in sorted(species_abilities.items()):
            f.write(f'  {sid}: [{abs[0]}, {abs[1]}],\n')
        f.write('};\n\n')

        # Vue 应用
        f.write('''
const { createApp, ref, computed, reactive, watch } = Vue;

const SearchSelect = {
  props: {
    modelValue: { type: Number, default: 0 },
    options: { type: Array, default: () => [] },
    placeholder: { type: String, default: '-- 选择 --' }
  },
  emits: ['update:modelValue'],
  data() { return { search: '', isOpen: false }; },
  computed: {
    selectedDisplay() {
      const opt = this.options.find(o => o.id === this.modelValue);
      return opt ? opt.display : '';
    },
    filteredOptions() {
      if (!this.search) return this.options.slice(0, 100);
      const q = this.search.toLowerCase();
      return this.options.filter(o => o.display.toLowerCase().includes(q)).slice(0, 100);
    }
  },
  methods: {
    open() { this.isOpen = true; this.search = ''; },
    close() { this.isOpen = false; this.search = ''; },
    select(id) { this.$emit('update:modelValue', id); this.close(); }
  },
  mounted() {
    document.addEventListener('click', (e) => {
      if (!this.$el.contains(e.target)) this.close();
    });
  },
  template: `
    <div class="search-select" @click.stop>
      <input type="text" v-model="search" :placeholder="selectedDisplay || placeholder" @focus="open" @input="isOpen = true">
      <div class="dropdown" v-show="isOpen">
        <div class="option" @click="select(0)">-- 无 --</div>
        <div v-for="opt in filteredOptions" :key="opt.id" class="option" :class="{selected: opt.id === modelValue}" @click="select(opt.id)">{{ opt.display }}</div>
        <div v-if="filteredOptions.length === 0" class="no-results">无匹配</div>
      </div>
    </div>
  `
};

// 默认精灵数据
function defaultPokemon() {
  return {
    species: 0,
    level: 50,
    item: 0,
    abilityNum: 0,
    moves: [0, 0, 0, 0],
    ivs: { hp: 31, attack: 31, defense: 31, spAttack: 31, spDefense: 31, speed: 31 },
    evs: { hp: 0, attack: 0, defense: 0, spAttack: 0, spDefense: 0, speed: 0 }
  };
}

// 生成 Lua 脚本（完整版）
function generateLua(team) {
  const lines = [];
  lines.push('-- 完整训练师队伍注入脚本');
  lines.push('local ADDR = 0x0203D000');
  lines.push('local MAGIC = 0xDEADBEEF');
  lines.push('');
  lines.push('local HEADER_SIZE = 8');
  lines.push('local MON_SIZE = 64');
  lines.push('');
  lines.push('local OFF_SPECIES      = 0x00');
  lines.push('local OFF_ITEM         = 0x02');
  lines.push('local OFF_MOVES        = 0x04');
  lines.push('local OFF_PP           = 0x0C');
  lines.push('local OFF_PP_BONUSES   = 0x10');
  lines.push('local OFF_LEVEL        = 0x11');
  lines.push('local OFF_FRIENDSHIP   = 0x12');
  lines.push('local OFF_ABILITY_NUM  = 0x13');
  lines.push('local OFF_PERSONALITY  = 0x14');
  lines.push('local OFF_HP_IV        = 0x18');
  lines.push('local OFF_ATK_IV       = 0x19');
  lines.push('local OFF_DEF_IV       = 0x1A');
  lines.push('local OFF_SPEED_IV     = 0x1B');
  lines.push('local OFF_SPATK_IV     = 0x1C');
  lines.push('local OFF_SPDEF_IV     = 0x1D');
  lines.push('local OFF_HP_EV        = 0x1E');
  lines.push('local OFF_ATK_EV       = 0x1F');
  lines.push('local OFF_DEF_EV       = 0x20');
  lines.push('local OFF_SPEED_EV     = 0x21');
  lines.push('local OFF_SPATK_EV     = 0x22');
  lines.push('local OFF_SPDEF_EV     = 0x23');
  lines.push('local OFF_STATUS1      = 0x24');
  lines.push('local OFF_OT_ID        = 0x28');
  lines.push('local OFF_CURRENT_HP   = 0x2C');
  lines.push('local OFF_STAT_STAGES  = 0x30');
  lines.push('local OFF_STATUS2      = 0x38');
  lines.push('local OFF_ABILITY      = 0x3C');
  lines.push('local OFF_TYPES        = 0x3D');
  lines.push('');
  lines.push('local function write_u32(addr, val) memory.write_u32_le(addr, val) end');
  lines.push('local function write_u16(addr, val) memory.write_u16_le(addr, val) end');
  lines.push('local function write_u8(addr, val) memory.write_u8(addr, val) end');
  lines.push('local function read_u32(addr) return memory.read_u32_le(addr) end');
  lines.push('local function read_u8(addr) return memory.read_u8(addr) end');
  lines.push('');
  lines.push('local function getMonAddr(i)');
  lines.push('    return ADDR + HEADER_SIZE + i * MON_SIZE');
  lines.push('end');
  lines.push('');
  lines.push('local function writeMon(i, data)');
  lines.push('    local base = getMonAddr(i)');
  lines.push('    write_u16(base + OFF_SPECIES, data.species or 0)');
  lines.push('    write_u16(base + OFF_ITEM, data.item or 0)');
  lines.push('    for j = 1, 4 do');
  lines.push('        write_u16(base + OFF_MOVES + (j-1)*2, data.moves and data.moves[j] or 0)');
  lines.push('        write_u8(base + OFF_PP + (j-1), data.pp and data.pp[j] or 0)');
  lines.push('    end');
  lines.push('    write_u8(base + OFF_PP_BONUSES, data.ppBonuses or 0)');
  lines.push('    write_u8(base + OFF_LEVEL, data.level or 50)');
  lines.push('    write_u8(base + OFF_FRIENDSHIP, data.friendship or 255)');
  lines.push('    write_u8(base + OFF_ABILITY_NUM, data.abilityNum or 0)');
  lines.push('    write_u32(base + OFF_PERSONALITY, data.personality or 0)');
  lines.push('    write_u8(base + OFF_HP_IV, data.hpIV or 31)');
  lines.push('    write_u8(base + OFF_ATK_IV, data.atkIV or 31)');
  lines.push('    write_u8(base + OFF_DEF_IV, data.defIV or 31)');
  lines.push('    write_u8(base + OFF_SPEED_IV, data.speedIV or 31)');
  lines.push('    write_u8(base + OFF_SPATK_IV, data.spAtkIV or 31)');
  lines.push('    write_u8(base + OFF_SPDEF_IV, data.spDefIV or 31)');
  lines.push('    write_u8(base + OFF_HP_EV, data.hpEV or 0)');
  lines.push('    write_u8(base + OFF_ATK_EV, data.atkEV or 0)');
  lines.push('    write_u8(base + OFF_DEF_EV, data.defEV or 0)');
  lines.push('    write_u8(base + OFF_SPEED_EV, data.speedEV or 0)');
  lines.push('    write_u8(base + OFF_SPATK_EV, data.spAtkEV or 0)');
  lines.push('    write_u8(base + OFF_SPDEF_EV, data.spDefEV or 0)');
  lines.push('    write_u32(base + OFF_STATUS1, data.status1 or 0)');
  lines.push('    write_u32(base + OFF_OT_ID, data.otId or 0)');
  lines.push('    write_u16(base + OFF_CURRENT_HP, data.currentHP or 0)');
  lines.push('    for j = 0, 7 do');
  lines.push('        write_u8(base + OFF_STAT_STAGES + j, data.statStages and data.statStages[j+1] or 6)');
  lines.push('    end');
  lines.push('    write_u32(base + OFF_STATUS2, data.status2 or 0)');
  lines.push('    write_u8(base + OFF_ABILITY, data.abilityOverride or 0)');
  lines.push('    write_u8(base + OFF_TYPES, data.type1 or 0)');
  lines.push('    write_u8(base + OFF_TYPES + 1, data.type2 or 0)');
  lines.push('end');
  lines.push('');
  lines.push('local function writeHeader(partySize, enabled)');
  lines.push('    write_u32(ADDR, MAGIC)');
  lines.push('    write_u8(ADDR + 4, partySize)');
  lines.push('    write_u8(ADDR + 5, enabled and 1 or 0)');
  lines.push('end');
  lines.push('');
  lines.push('local party = {');

  team.forEach((p) => {
    if (p.species > 0) {
      const moves = p.moves.filter(m => m > 0);
      const pp = moves.map(() => 15);
      lines.push('    {');
      lines.push(`        species = ${p.species},`);
      lines.push(`        item = ${p.item || 0},`);
      lines.push(`        moves = { ${moves.join(', ')} },`);
      lines.push(`        pp = { ${pp.join(', ')} },`);
      lines.push('        ppBonuses = 0,');
      lines.push(`        level = ${p.level},`);
      lines.push('        friendship = 255,');
      lines.push(`        abilityNum = ${p.abilityNum},`);
      lines.push('        personality = 0,');
      lines.push(`        hpIV = ${p.ivs.hp}, atkIV = ${p.ivs.attack}, defIV = ${p.ivs.defense}, speedIV = ${p.ivs.speed}, spAtkIV = ${p.ivs.spAttack}, spDefIV = ${p.ivs.spDefense},`);
      lines.push(`        hpEV = ${p.evs.hp}, atkEV = ${p.evs.attack}, defEV = ${p.evs.defense}, speedEV = ${p.evs.speed}, spAtkEV = ${p.evs.spAttack}, spDefEV = ${p.evs.spDefense},`);
      lines.push('        status1 = 0,');
      lines.push('        otId = 0,');
      lines.push('        currentHP = 0,');
      lines.push('        statStages = {6, 6, 6, 6, 6, 6, 6, 6},');
      lines.push('        status2 = 0,');
      lines.push('        abilityOverride = 0,');
      lines.push('        type1 = 0,');
      lines.push('        type2 = 0,');
      lines.push('    },');
    }
  });

  lines.push('}');
  lines.push('');
  lines.push('writeHeader(#party, true)');
  lines.push('for i, mon in ipairs(party) do');
  lines.push('    writeMon(i - 1, mon)');
  lines.push('end');
  lines.push('');
  lines.push('print("=== 注入完成 ===")');
  lines.push('print(string.format("Party Size: %d", read_u8(ADDR + 4)))');

  return lines.join('\\n');
}

createApp({
  components: { SearchSelect },
  setup() {
    const selectedIndex = ref(null);
    const team = reactive([defaultPokemon(), defaultPokemon(), defaultPokemon(), defaultPokemon(), defaultPokemon(), defaultPokemon()]);

    const currentAbilities = computed(() => {
      if (selectedIndex.value === null || !team[selectedIndex.value].species) return [];
      const abs = SPECIES_ABILITIES[team[selectedIndex.value].species] || [];
      const result = [];
      if (abs[0] > 0 && ABILITIES_DATA[abs[0]]) result.push({num:0, display: ABILITIES_DATA[abs[0]].display});
      if (abs[1] > 0 && ABILITIES_DATA[abs[1]]) result.push({num:1, display: ABILITIES_DATA[abs[1]].display});
      return result;
    });

    watch(() => selectedIndex.value !== null ? team[selectedIndex.value].species : null, () => {
      if (selectedIndex.value !== null) team[selectedIndex.value].abilityNum = 0;
    });

    const toastVisible = ref(false);
    const toastMessage = ref('');

    return {
      team, selectedIndex,
      speciesOptions: SPECIES_DATA.filter(x=>x),
      movesOptions: MOVES_DATA.filter(x=>x),
      itemsOptions: ITEMS_DATA.filter(x=>x),
      currentAbilities,
      selectSlot: (i) => { selectedIndex.value = i; },
      clearSlot: () => { if (selectedIndex.value !== null) team[selectedIndex.value] = defaultPokemon(); },
      resetTeam: () => {
        for(let i=0;i<6;i++) team[i] = defaultPokemon();
        selectedIndex.value = null;
        toastMessage.value = '已重置'; toastVisible.value = true; setTimeout(()=>toastVisible.value=false, 2000);
      },
      getSpeciesName: (id) => SPECIES_DATA[id]?.display || 'Empty',
      generatedScript: computed(() => generateLua(team)),
      copyScript: async () => {
        try { await navigator.clipboard.writeText(generateLua(team)); toastMessage.value='已复制'; }
        catch { toastMessage.value='失败'; }
        toastVisible.value = true; setTimeout(()=>toastVisible.value=false, 2000);
      },
      downloadScript: () => {
        const blob = new Blob([generateLua(team)], {type:'text/plain'});
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = 'inject_party.lua';
        a.click();
      },
      toastVisible, toastMessage
    };
  }
}).mount('#app');
''')

    print(f'Generated: {len(species)} species, {len(moves)} moves, {len(abilities)} abilities, {len(items)} items, {len(species_abilities)} ability mappings')

if __name__ == '__main__':
    main()
