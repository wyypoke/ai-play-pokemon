package com.xiaobaozi.ai_play_pokemon.emulator.dto;

/**
 * 任务项
 */
public class TodoItem {

    /**
     * 唯一标识
     */
    private String id;

    /**
     * 任务描述
     */
    private String description;

    /**
     * 优先级（1最高）
     */
    private int priority;

    /**
     * 是否完成
     */
    private boolean completed;

    public TodoItem() {
    }

    public TodoItem(String id, String description, int priority, boolean completed) {
        this.id = id;
        this.description = description;
        this.priority = priority;
        this.completed = completed;
    }

    /**
     * 创建未完成的任务
     */
    public static TodoItem of(String id, String description, int priority) {
        return new TodoItem(id, description, priority, false);
    }

    /**
     * 标记完成
     */
    public TodoItem complete() {
        this.completed = true;
        return this;
    }

    // ==================== Getter/Setter ====================

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public int getPriority() {
        return priority;
    }

    public void setPriority(int priority) {
        this.priority = priority;
    }

    public boolean isCompleted() {
        return completed;
    }

    public void setCompleted(boolean completed) {
        this.completed = completed;
    }

    @Override
    public String toString() {
        String status = completed ? "[✓]" : "[ ]";
        return status + " " + id + ". " + description + " (优先级:" + priority + ")";
    }
}
