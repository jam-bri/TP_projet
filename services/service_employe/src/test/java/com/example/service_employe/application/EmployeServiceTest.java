package com.example.service_employe.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.service_employe.infrastructure.EmployeRepository;

// Mockito remplace par un faux objet (mock) : on teste la logique du service seule, sans base de données
@ExtendWith(MockitoExtension.class)
class EmployeServiceTest {

    @Mock
    private EmployeRepository repo;

    @InjectMocks
    private EmployeService service;

    @Test
    void getEmployes_retourneTousLesEmployesDuRepository() {
        when(repo.findAll()).thenReturn(List.of(new Employe(1, "Alice"), new Employe(2, "Bob")));

        assertThat(service.getEmployes()).extracting(Employe::getNom).containsExactly("Alice", "Bob");
    }

    @Test
    void creationEmploye_enregistreLEmploye() {
        Employe employe = new Employe(0, "Alice");

        service.creationEmploye(employe);

        verify(repo).save(employe);
    }

    @Test
    void getEmployesByIds_ignoreLesIdsInexistants() {
        when(repo.findById(1)).thenReturn(Optional.of(new Employe(1, "Alice")));
        when(repo.findById(99)).thenReturn(Optional.empty());

        List<Employe> resultat = service.getEmployesByIds(List.of(1, 99));

        assertThat(resultat).extracting(Employe::getId).containsExactly(1);
    }

    @Test
    void getEmployesByIds_listeVide_neConsultePasLaBase() {
        assertThat(service.getEmployesByIds(List.of())).isEmpty();

        verify(repo, never()).findById(anyInt());
    }
}
