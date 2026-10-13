package com.example.service_employe.presentation;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;

import org.junit.jupiter.api.Test;

import com.example.service_employe.application.Employe;

class EmployeMapperTest {

    private final EmployeMapper mapper = new EmployeMapper();

    @Test
    void mapEmployeToEmployeDTO_copieIdEtNom() {
        Employe employe = new Employe(7, "Alice");

        EmployeDTO dto = mapper.mapEmployeToEmployeDTO(employe);

        assertThat(dto.getId()).isEqualTo(7);
        assertThat(dto.getNom()).isEqualTo("Alice");
    }

    @Test
    void mapEmployeDTOToEmploye_copieIdEtNom() {
        CreationEmployeDTO dto = new CreationEmployeDTO(3, "Bob", List.of(1, 2));

        Employe employe = mapper.mapEmployeDTOToEmploye(dto);

        assertThat(employe.getId()).isEqualTo(3);
        assertThat(employe.getNom()).isEqualTo("Bob");
    }
}
