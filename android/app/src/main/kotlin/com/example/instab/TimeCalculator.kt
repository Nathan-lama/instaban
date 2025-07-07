package com.example.instab

object TimeCalculator {
    
    fun calculateInterval(timeSpent: Long): Long {
        return when {
            timeSpent < 60 -> 60     // Première minute: attendre 60s
            timeSpent < 120 -> 30    // 2ème minute: toutes les 30s
            timeSpent < 180 -> 15    // 3ème minute: toutes les 15s
            timeSpent < 300 -> 10    // Jusqu'à 5 min: toutes les 10s
            timeSpent < 600 -> 5     // Jusqu'à 10 min: toutes les 5s
            else -> 2                // Après 10 min: toutes les 2s
        }
    }
}